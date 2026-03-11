using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
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

        public OwnerService(_220030Context db)
        {
            _db = db;
        }

        public async Task<int> GetTodaysReservations(int localeId)
        {
            var today = DateTime.Today;
            return await _db.Reservations
                .Where(x => x.ReservationDate.Date == today &&
                            x.Table.LocaleId == localeId &&
                            !x.IsCancelled)
                .CountAsync();
        }

        public async Task<int> GetTodaysGuests(int localeId)
        {
            var today = DateTime.Today;
            return await _db.Reservations
                .Where(r => r.ReservationDate.Date == today &&
                            r.Table.LocaleId == localeId &&
                            !r.IsCancelled)
                .SumAsync(r => r.Table.NumberOfGuests);
        }

        public async Task<int> GetActiveTables(int localeId)
        {
            var today = DateTime.Today;
            return await _db.Reservations
                .Where(r => r.ReservationDate.Date == today &&
                            r.Table.LocaleId == localeId &&
                            !r.IsCancelled)
                .Select(r => r.TableId)
                .Distinct()
                .CountAsync();
        }

        public async Task<int> GetTotalTables(int localeId)
        {
            return await _db.Tables
                .Where(t => t.LocaleId == localeId)
                .CountAsync();
        }

        public async Task<object> GetMyLocale(int localeId)
        {
            var locale = await _db.Locales
                .Include(l => l.City)
                .Include(l => l.Category)
                .FirstOrDefaultAsync(l => l.Id == localeId);

            if (locale == null)
                throw new Exception("Lokal nije pronađen!");

            return locale;
        }

        public async Task<object> GetTableDistribution(int localeId)
        {
            var total = await _db.Tables
                .Where(t => t.LocaleId == localeId)
                .CountAsync();

            if (total == 0) return new List<object>();

            return await _db.Tables
                .Where(t => t.LocaleId == localeId)
                .GroupBy(t => t.NumberOfGuests)
                .Select(g => new
                {
                    Seats = g.Key,
                    Count = g.Count(),
                    Percentage = (double)g.Count() * 100 / total
                })
                .ToListAsync();
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
            if (locale == null) throw new Exception("Lokal nije pronađen!");
            return locale.OwnerId == userId;
        }

        public async Task<bool> CheckIfOwnerOrWorker(int localeId, int userId)
        {
            var locale = await _db.Locales.FirstOrDefaultAsync(x => x.Id == localeId);
            if (locale == null) throw new Exception("Lokal nije pronađen!");
            if (locale.OwnerId == userId) return true;
            return await _db.Workers.AnyAsync(w => w.LocaleId == localeId && w.UserId == userId);
        }
    
    }
}
