using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Model.Exceptions;
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

        public OwnerService(_220030Context db, ILogger<OwnerService> logger)
        {
            _db = db;
            _logger = logger;
        }

        public async Task<int> GetTodaysReservations(int localeId)
        {
            var today = DateTime.Today;
            var count = await _db.Reservations
                .Where(x => x.ReservationDate.Date == today &&
                            x.Table.LocaleId == localeId &&
                            !x.IsCancelled)
                .CountAsync();
            return count;
        }

        public async Task<int> GetTodaysGuests(int localeId)
        {
            var today = DateTime.Today;
            var guests = await _db.Reservations
                .Where(r => r.ReservationDate.Date == today &&
                            r.Table.LocaleId == localeId &&
                            !r.IsCancelled)
                .SumAsync(r => r.Table.NumberOfGuests);
            return guests;
        }

        public async Task<int> GetActiveTables(int localeId)
        {
            var today = DateTime.Today;
            var count = await _db.Reservations
                .Where(r => r.ReservationDate.Date == today &&
                            r.Table.LocaleId == localeId &&
                            !r.IsCancelled)
                .Select(r => r.TableId)
                .Distinct()
                .CountAsync();
            return count;
        }

        public async Task<int> GetTotalTables(int localeId)
        {
            var count = await _db.Tables
                .Where(t => t.LocaleId == localeId)
                .CountAsync();
            return count;
        }

        public async Task<object> GetMyLocale(int localeId)
        {
            var locale = await _db.Locales
                .Include(l => l.City)
                .Include(l => l.Category)
                .FirstOrDefaultAsync(l => l.Id == localeId);

            if (locale == null)
            {
                _logger.LogWarning("Locale details not found. LocaleId: {LocaleId}", localeId);
                throw new UserException("Lokal nije pronađen!");
            }

            return locale;
        }

        public async Task<object> GetTableDistribution(int localeId)
        {
            var total = await _db.Tables
                .Where(t => t.LocaleId == localeId)
                .CountAsync();

            if (total == 0)
            {
                return new List<object>();
            }

            var distribution = await _db.Tables
                .Where(t => t.LocaleId == localeId)
                .GroupBy(t => t.NumberOfGuests)
                .Select(g => new
                {
                    Seats = g.Key,
                    Count = g.Count(),
                    Percentage = (double)g.Count() * 100 / total
                })
                .ToListAsync();
            return distribution;
        }

        public async Task<object> GetAllReservations(int userId, string? q, DateTime? date, int page, int pageSize)
        {
            var selectedDate = (date?.Date ?? DateTime.Today);

            var query = _db.Reservations
                .Include(r => r.Table).ThenInclude(t => t.Locale)
                .Include(r => r.User)
                .AsQueryable();

            var isOwner = await _db.Locales.AnyAsync(l => l.OwnerId == userId);
            var worker = await _db.Workers.FirstOrDefaultAsync(w => w.UserId == userId);

            if (isOwner)
                query = query.Where(x => x.ReservationDate.Date == selectedDate &&
                                         x.Table.Locale.OwnerId == userId);
            else if (worker != null)
                query = query.Where(x => x.ReservationDate.Date == selectedDate &&
                                         x.Table.LocaleId == worker.LocaleId);

            if (!string.IsNullOrWhiteSpace(q))
                query = query.Where(s =>
                    s.User.FirstName.Contains(q) ||
                    s.User.LastName.Contains(q) ||
                    s.Table.Name.Contains(q));

            var total = await query.CountAsync();

            var result = await query
                .Skip(page * pageSize)
                .Take(pageSize)
                .Select(s => new
                {
                    s.Id,
                    s.User.FirstName,
                    s.User.LastName,
                    ReservationDate = s.ReservationDate,
                    StartTime = s.StartTime,
                    Guests = s.Table.NumberOfGuests,
                    TableName = s.Table.Name,
                    s.IsCancelled
                })
                .ToListAsync();

            return new { Items = result, TotalCount = total };
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
