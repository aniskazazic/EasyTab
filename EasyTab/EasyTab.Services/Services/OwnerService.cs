using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Responses;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class OwnerService : IOwnerService
    {
        private readonly _220030Context _db;
        private readonly ILogger<OwnerService> _logger;
        private readonly ILocaleAccessService _localeAccessService;

        public OwnerService(_220030Context db, ILogger<OwnerService> logger, ILocaleAccessService localeAccessService)
        {
            _db = db;
            _logger = logger;
            _localeAccessService = localeAccessService;
        }

        public async Task<int> GetTodaysReservations(int localeId)
        {
            await _localeAccessService.EnsureCanManageLocaleAsync(localeId);
            var today = DateTime.Today;
            var count = await _db.Reservations
                .Where(x => x.ReservationDate.Date == today &&
                            x.Table.LocaleId == localeId &&
                            x.ReservationState != "Otkazana")
                .CountAsync();
            return count;
        }

        public async Task<int> GetTodaysGuests(int localeId)
        {
            await _localeAccessService.EnsureCanManageLocaleAsync(localeId);
            var today = DateTime.Today;
            var guests = await _db.Reservations
                .Where(r => r.ReservationDate.Date == today &&
                            r.Table.LocaleId == localeId &&
                            r.ReservationState != "Otkazana")
                .SumAsync(r => r.Table.NumberOfGuests);
            return guests;
        }

        public async Task<int> GetActiveTables(int localeId)
        {
            await _localeAccessService.EnsureCanManageLocaleAsync(localeId);
            var today = DateTime.Today;
            var count = await _db.Reservations
                .Where(r => r.ReservationDate.Date == today &&
                            r.Table.Xcoordinate >= 0 && r.Table.Ycoordinate >= 0 &&
                            r.Table.LocaleId == localeId &&
                            r.ReservationState != "Otkazana")
                .Select(r => r.TableId)
                .Distinct()
                .CountAsync();
            return count;
        }

        public async Task<int> GetTotalTables(int localeId)
        {
            await _localeAccessService.EnsureCanManageLocaleAsync(localeId);
            var count = await _db.Tables.OnLayout()
                .Where(t => t.LocaleId == localeId)
                .CountAsync();
            return count;
        }

        public async Task<OwnerLocaleResponse> GetMyLocale(int localeId)
        {
            await _localeAccessService.EnsureCanManageLocaleAsOwnerAsync(localeId);
            var locale = await _db.Locales
                .Include(l => l.City)
                .Include(l => l.Category)
                .FirstOrDefaultAsync(l => l.Id == localeId);

            if (locale == null)
            {
                _logger.LogWarning("Locale details not found. LocaleId: {LocaleId}", localeId);
                throw new UserException("Lokal nije pronađen!");
            }

            return new OwnerLocaleResponse
            {
                Id = locale.Id,
                Name = locale.Name,
                Address = locale.Address,
                StartOfWorkingHours = locale.StartOfWorkingHours,
                EndOfWorkingHours = locale.EndOfWorkingHours,
                LengthOfReservation = locale.LengthOfReservation,
                Logo = locale.Logo,
                CityId = locale.CityId,
                CategoryId = locale.CategoryId,
                OwnerId = locale.OwnerId,
                IsDeleted = locale.IsDeleted,
                DeletedAt = locale.DeletedAt,
                PhoneNumber = locale.PhoneNumber
            };
        }

        public async Task<List<TableDistributionResponse>> GetTableDistribution(int localeId)
        {
            await _localeAccessService.EnsureCanManageLocaleAsync(localeId);
            var total = await _db.Tables.OnLayout()
                .Where(t => t.LocaleId == localeId)
                .CountAsync();

            if (total == 0)
            {
                return new List<TableDistributionResponse>();
            }

            var distribution = await _db.Tables.OnLayout()
                .Where(t => t.LocaleId == localeId)
                .GroupBy(t => t.NumberOfGuests)
                .Select(g => new TableDistributionResponse
                {
                    Seats = g.Key,
                    Count = g.Count(),
                    Percentage = (double)g.Count() * 100 / total
                })
                .ToListAsync();
            return distribution;
        }

        public async Task<OwnerReservationsPageResponse> GetAllReservations(int userId, string? q, DateTime? date, int page, int pageSize)
        {
            page = Math.Max(page, 0);
            pageSize = Math.Clamp(pageSize, 1, 100);
            var selectedDate = (date?.Date ?? DateTime.Today);

            var query = _db.Reservations
                .Include(r => r.Table).ThenInclude(t => t.Locale)
                .Include(r => r.User)
                .AsQueryable();

            var isOwner = await _db.Locales.AnyAsync(l => l.OwnerId == userId);
            var worker = await _db.Workers.FirstOrDefaultAsync(w => w.UserId == userId && !w.IsDeleted);

            if (!isOwner && worker == null)
                throw new ForbiddenException("Niste dodijeljeni lokalu. Obratite se vlasniku lokala.");

            if (isOwner)
                query = query.Where(x => x.ReservationDate.Date == selectedDate &&
                                         x.Table.Locale.OwnerId == userId &&
                                         x.ReservationState != "Otkazana" &&
                                         x.ReservationState != "Završena");
            else if (worker != null)
                query = query.Where(x => x.ReservationDate.Date == selectedDate &&
                                         x.Table.LocaleId == worker.LocaleId &&
                                         x.ReservationState != "Otkazana" &&
                                         x.ReservationState != "Završena");

            if (!string.IsNullOrWhiteSpace(q))
                query = query.Where(s =>
                    s.User.FirstName.Contains(q) ||
                    s.User.LastName.Contains(q) ||
                    s.Table.Name.Contains(q));

            var total = await query.CountAsync();

            var result = await query
                .OrderByDescending(s => s.ReservationDate)
                .ThenByDescending(s => s.StartTime)
                .ThenBy(s => s.Id)
                .Skip((int)Math.Min((long)page * pageSize, int.MaxValue))
                .Take(pageSize)
                .Select(s => new OwnerReservationListItemResponse
                {
                    Id = s.Id,
                    FirstName = s.User.FirstName,
                    LastName = s.User.LastName,
                    ReservationDate = s.ReservationDate,
                    StartTime = s.StartTime,
                    EndTime = s.EndTime,
                    NumberOfGuests = s.Table.NumberOfGuests,
                    TableName = s.Table.Name,
                    ReservationState = s.ReservationState,
                    LocaleName = s.Table.Locale.Name,
                    IsCancelled = s.ReservationState == "Otkazana"
                })
                .ToListAsync();

            return new OwnerReservationsPageResponse { Items = result, TotalCount = total };
        }

        public async Task<bool> CheckIfOwner(int localeId, int userId)
        {
            var locale = await _db.Locales.FirstOrDefaultAsync(x => x.Id == localeId);
            if (locale == null)
            {
                _logger.LogWarning("Owner check failed because locale was not found. LocaleId: {LocaleId}", localeId);
                throw new UserException("Lokal nije pronađen!");
            }
            var isOwner = locale.OwnerId == userId;
            return isOwner;
        }

        public async Task<bool> CheckIfOwnerOrWorker(int localeId, int userId)
        {
            var locale = await _db.Locales.FirstOrDefaultAsync(x => x.Id == localeId);
            if (locale == null)
            {
                _logger.LogWarning("Owner/worker check failed because locale was not found. LocaleId: {LocaleId}", localeId);
                throw new UserException("Lokal nije pronađen!");
            }
            if (locale.OwnerId == userId)
            {
                return true;
            }

            var isWorker = await _db.Workers.AnyAsync(w => w.LocaleId == localeId && w.UserId == userId);
            return isWorker;
        }
    
    }
}
