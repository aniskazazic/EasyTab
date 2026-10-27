using EasyTab.Model.Models;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.ReservationStateMachine;
using EasyTab.Model;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class TableService : BaseCRUDService<Tables, TableSearchObject, Table, TableInsertRequest, TableUpdateRequest>, ITableService
    {
        private readonly ILogger<TableService> _logger;
        private readonly ILocaleAccessService _localeAccessService;

        public TableService(_220030Context context, IMapper mapper, ILogger<TableService> logger, IValidator<TableInsertRequest> insertValidator, IValidator<TableUpdateRequest> updateValidator, ILocaleAccessService localeAccessService) 
            : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
            _localeAccessService = localeAccessService;
        }

        public override async Task<Tables> CreateAsync(TableInsertRequest request)
        {
            await _localeAccessService.EnsureCanManageLocaleAsync(request.LocaleId);
            TableLayoutExtensions.ValidatePosition(request.XCoordinate, request.YCoordinate);
            _logger.LogInformation("Creating table. TableName: {TableName}", request.Name);
            return await base.CreateAsync(request);
        }

        public override async Task<Tables?> UpdateAsync(int id, TableUpdateRequest request)
        {
            await using var transaction = await Context.Database.BeginTransactionAsync();
            var table = await GetTableForUpdateAsync(id);
            await _localeAccessService.EnsureCanManageLocaleAsync(table.LocaleId);
            TableLayoutExtensions.ValidatePosition(request.XCoordinate, request.YCoordinate);
            _logger.LogInformation("Updating table. TableId: {TableId}, TableName: {TableName}", id, request.Name);
            var updated = await base.UpdateAsync(id, request);
            await transaction.CommitAsync();
            return updated;
        }

        private async Task<Table> GetTableForUpdateAsync(int id)
        {
            var table = await Context.Tables
                .FromSqlInterpolated($"SELECT * FROM [Tables] WITH (UPDLOCK, HOLDLOCK) WHERE [Id] = {id}")
                .SingleOrDefaultAsync();
            if (table == null || table.IsRemoved())
                throw new NotFoundException("Stol nije pronađen.");
            return table;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            await using var transaction = await Context.Database.BeginTransactionAsync();
            var table = await GetTableForUpdateAsync(id);
            await _localeAccessService.EnsureCanManageLocaleAsync(table.LocaleId);
            await EnsureCanDeleteAsync(new[] { id });
            _logger.LogWarning("Deleting table. TableId: {TableId}", id);
            table.RemoveFromLayout();
            await Context.SaveChangesAsync();
            await transaction.CommitAsync();
            return true;
        }

        private IQueryable<Table> TablesWithActiveObligations(int[] tableIds)
        {
            var now = LocalClock.Now;
            var currentTime = TimeOnly.FromDateTime(now);
            return Context.Tables.Where(table => tableIds.Contains(table.Id) &&
                (table.Reservations.Any(reservation =>
                    reservation.ReservationState != CancelledReservationState.StateName &&
                    reservation.ReservationState != CompletedReservationState.StateName &&
                    (reservation.ReservationDate.Date > now.Date ||
                     (reservation.ReservationDate.Date == now.Date && reservation.EndTime > currentTime))) ||
                 Context.Payments.Any(payment => payment.Status == PaymentStatus.Created &&
                    (payment.TableId == table.Id ||
                     (payment.Reservation != null && payment.Reservation.TableId == table.Id)))));
        }

        private async Task EnsureCanDeleteAsync(int[] tableIds)
        {
            if (tableIds.Length == 0)
                return;

            if (await TablesWithActiveObligations(tableIds).AnyAsync())
                throw new UserException("Stol se ne može obrisati dok ima aktivnu ili buduću rezervaciju ili nezavršeno plaćanje.");
        }

        public override async Task<PagedResult<Tables>> GetAsync(TableSearchObject search)
        {
            var result = await base.GetAsync(search);
            var blockedIds = await TablesWithActiveObligations(result.Items.Select(table => table.Id).ToArray())
                .Select(table => table.Id).ToListAsync();
            foreach (var table in result.Items)
                table.CanDelete = !blockedIds.Contains(table.Id);
            return result;
        }

        public override async Task<Tables?> GetByIdAsync(int id)
        {
            var entity = await Context.Tables.OnLayout().AsNoTracking()
                .SingleOrDefaultAsync(table => table.Id == id);
            if (entity == null)
                throw new NotFoundException("Stol nije pronađen.");
            var table = MapToResponse(entity);
            table.CanDelete = !await TablesWithActiveObligations(new[] { id }).AnyAsync();
            return table;
        }

        protected override IQueryable<Table> ApplyFilter(IQueryable<Table> query, TableSearchObject? search)
        {
            query = query.OnLayout();
            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.LocaleId == search.LocaleId);

            return query;
        }

        protected override Tables MapToResponse(Table entity)
        {
            return new Tables
            {
                Id = entity.Id,
                Name = entity.Name,
                LocaleId = entity.LocaleId,
                XCoordinate = entity.Xcoordinate,
                YCoordinate = entity.Ycoordinate,
                NumberOfGuests = entity.NumberOfGuests
            };
        }

        public async Task SaveLayoutAsync(TableLayoutRequest request)
        {
            await _localeAccessService.EnsureCanManageLocaleAsync(request.LocaleId);
            _logger.LogInformation("Saving table layout. LocaleId: {LocaleId}", request.LocaleId);

            foreach (var table in request.Tables)
                TableLayoutExtensions.ValidatePosition(table.XCoordinate, table.YCoordinate);

            await using var transaction = await Context.Database.BeginTransactionAsync();
            var existingTables = await Context.Tables
               .FromSqlInterpolated($"SELECT * FROM [Tables] WITH (UPDLOCK, HOLDLOCK) WHERE [LocaleId] = {request.LocaleId}")
               .OnLayout()
               .ToListAsync();

            if (request.Tables.Any(table => table.Id != 0 && !existingTables.Any(existing => existing.Id == table.Id)))
                throw new UserException("Tlocrt sadrži stol koji više nije dostupan. Osvježite tlocrt i pokušajte ponovo.");

            // Obriši stolove koji nisu poslani s frontenda
            var sentIds = request.Tables.Select(t => t.Id).ToList();
            var toDelete = existingTables.Where(x => !sentIds.Contains(x.Id)).ToList();
            await EnsureCanDeleteAsync(
                toDelete.Select(table => table.Id).ToArray());
            foreach (var table in toDelete)
                table.RemoveFromLayout();

            foreach (var table in request.Tables)
            {
                if (table.Id == 0)
                {
                    // Novi stol
                    _logger.LogInformation("Creating table from layout. TableName: {TableName}, LocaleId: {LocaleId}", table.Name, request.LocaleId);
                    Context.Tables.Add(new Table
                    {
                        LocaleId = request.LocaleId,
                        Name = table.Name,
                        Xcoordinate = table.XCoordinate,
                        Ycoordinate = table.YCoordinate,
                        NumberOfGuests = table.NumberOfGuests
                    });
                }
                else
                {
                    // Update postojećeg stola
                    var existing = existingTables.FirstOrDefault(x => x.Id == table.Id);
                    if (existing != null)
                    {
                        _logger.LogInformation("Updating table from layout. TableId: {TableId}, TableName: {TableName}", table.Id, table.Name);
                        existing.Name = table.Name;
                        existing.Xcoordinate = table.XCoordinate;
                        existing.Ycoordinate = table.YCoordinate;
                        existing.NumberOfGuests = table.NumberOfGuests;
                        Context.Update(existing);
                    }
                }
            }

            await Context.SaveChangesAsync();
            await transaction.CommitAsync();
        }
    }
}
