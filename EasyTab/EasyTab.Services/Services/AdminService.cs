using EasyTab.Model.Requests;
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
    public class AdminService : IAdminService
    {
        private readonly _220030Context _db;

        public AdminService(_220030Context db)
        {
            _db = db;
        }
        public async Task<object> GetAllLocales(string? search, bool showDeleted, int page, int pageSize)
        {
            var query = _db.Locales
                .Include(l => l.City).ThenInclude(c => c.Country)
                .Include(l => l.Category)
                .AsQueryable();

            if (!showDeleted)
                query = query.Where(x => !x.IsDeleted);

            if (!string.IsNullOrWhiteSpace(search))
                query = query.Where(x => x.Name.ToLower().Contains(search.ToLower()));

            var total = await query.CountAsync();

            var result = await query
                .Skip(page * pageSize)
                .Take(pageSize)
                .Select(c => new
                {
                    c.Id,
                    LocaleName = c.Name,
                    City = c.City.Name,
                    Country = c.City.Country.Name,
                    Category = c.Category.Name,
                    c.Address,
                    c.IsDeleted,
                    CountryId = c.City.CountryId,
                    CityId = c.CityId,
                    CategoryId = c.CategoryId
                })
                .ToListAsync();

            return new { Items = result, TotalCount = total };
        }

        public async Task<object> GetAnalytics()
        {
            var users = await _db.Users.ToListAsync();
            var locales = await _db.Locales
                .Include(l => l.Category)
                .Include(l => l.City).ThenInclude(c => c.Country)
                .Where(l => !l.IsDeleted)
                .ToListAsync();

            var activeUsers = users.Count(u => !u.IsDeleted);
            var deletedUsers = users.Count(u => u.IsDeleted);

            var ownerCount = await _db.Locales.Select(l => l.OwnerId).Distinct().CountAsync();
            var workerCount = await _db.Workers.CountAsync();
            var normalUserCount = users.Count - ownerCount - workerCount;

            var categoryCounts = new int[3];
            categoryCounts[0] = locales.Count(l => l.Category?.Id == 1);
            categoryCounts[1] = locales.Count(l => l.Category?.Id == 2);
            categoryCounts[2] = locales.Count(l => l.Category?.Id == 3);

            var topCountries = locales
                .Where(l => l.City?.Country != null)
                .GroupBy(l => l.City.Country)
                .Select(g => new { CountryName = g.Key.Name, Count = g.Count() })
                .OrderByDescending(x => x.Count)
                .ToList();

            return new
            {
                UserStatsData = new[] { activeUsers, deletedUsers },
                UserRoleData = new[] { ownerCount, workerCount, normalUserCount },
                LocaleCategoryData = categoryCounts,
                LocaleCountyData = topCountries.Select(x => x.Count).ToArray(),
                CountyNames = topCountries.Select(x => x.CountryName).ToArray()
            };
        }

        public async Task<object> GetStats()
        {
            return new
            {
                CountOfUsers = await _db.Users.CountAsync(),
                CountOfDeletedUsers = await _db.Users.CountAsync(u => u.IsDeleted),
                CountOfActiveUsers = await _db.Users.CountAsync(u => !u.IsDeleted),
                CountOfLocales = await _db.Locales.CountAsync(l => !l.IsDeleted)
            };
        }

        public async Task ReactivateLocale(int id)
        {
            var locale = await _db.Locales.FirstOrDefaultAsync(x => x.IsDeleted && x.Id == id);
            if (locale == null)
                throw new Exception("Lokal nije pronađen!");

            locale.IsDeleted = false;
            locale.DeletedAt = null;

            _db.Locales.Update(locale);
            await _db.SaveChangesAsync();
        }

        public async Task UpdateLocale(int id, AdminUpdateLocaleRequest request)
        {
            var locale = await _db.Locales.FirstOrDefaultAsync(x => x.Id == id);
            if (locale == null)
                throw new Exception($"Lokal sa ID {id} nije pronađen!");

            locale.Name = request.LocaleName;
            locale.CityId = request.CityId;
            locale.Address = request.Address;
            locale.CategoryId = request.CategoryId;

            await _db.SaveChangesAsync();
        }
    }
}
