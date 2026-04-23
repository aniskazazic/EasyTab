using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class TableService : BaseCRUDService<Tables, TableSearchObject, Table, TableInsertRequest, TableUpdateRequest>, ITableService
    {
        private readonly ILogger<TableService> _logger;

        public TableService(_220030Context context, IMapper mapper, ILogger<TableService> logger, IValidator<TableInsertRequest> insertValidator, IValidator<TableUpdateRequest> updateValidator) 
            : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
        }

        public override async Task<Tables> CreateAsync(TableInsertRequest request)
        {
            _logger.LogInformation("Creating table. TableName: {TableName}", request.Name);
            return await base.CreateAsync(request);
        }

        public override async Task<Tables?> UpdateAsync(int id, TableUpdateRequest request)
        {
            _logger.LogInformation("Updating table. TableId: {TableId}, TableName: {TableName}", id, request.Name);
            return await base.UpdateAsync(id, request);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            _logger.LogWarning("Deleting table. TableId: {TableId}", id);
            return await base.DeleteAsync(id);
        }

        protected override IQueryable<Table> ApplyFilter(IQueryable<Table> query, TableSearchObject search)
        {
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

        public void SaveLayout(TableLayoutRequest request)
        {
            _logger.LogInformation("Saving table layout. LocaleId: {LocaleId}", request.LocaleId);

            var existingTables = Context.Tables
               .Where(x => x.LocaleId == request.LocaleId)
               .ToList();

            // Obriši stolove koji nisu poslani s frontenda
            var sentIds = request.Tables.Select(t => t.Id).ToList();
            var toDelete = existingTables.Where(x => !sentIds.Contains(x.Id)).ToList();
            Context.Tables.RemoveRange(toDelete);

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

            Context.SaveChanges();
        }
    }
}
