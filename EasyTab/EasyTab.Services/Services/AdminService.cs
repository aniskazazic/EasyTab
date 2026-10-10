using EasyTab.Model.Requests;
using EasyTab.Model.Responses;
using EasyTab.Model.Exceptions;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
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
        private readonly ILogger<AdminService> _logger;

        public AdminService(_220030Context db, ILogger<AdminService> logger)
        {
            _db = db;
            _logger = logger;
        }
        public async Task<AdminLocalePageResponse> GetAllLocales(string? search, bool showDeleted, int page, int pageSize)
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
                .OrderBy(c => c.Id)
                .Skip(page * pageSize)
                .Take(pageSize)
                .Select(c => new AdminLocaleListItemResponse
                {
                    Id = c.Id,
                    LocaleName = c.Name,
                    City = c.City.Name,
                    Country = c.City.Country.Name,
                    Category = c.Category.Name,
                    Address = c.Address,
                    IsDeleted = c.IsDeleted,
                    CountryId = c.City.CountryId,
                    CityId = c.CityId,
                    CategoryId = c.CategoryId
                })
                .ToListAsync();

            return new AdminLocalePageResponse { Items = result, TotalCount = total };
        }

        public async Task<AdminAnalyticsResponse> GetAnalytics()
        {
            var activeUsers = await _db.Users.CountAsync(u => !u.IsDeleted);
            var deletedUsers = await _db.Users.CountAsync(u => u.IsDeleted);
            var ownerCount = await _db.Locales.Select(l => l.OwnerId).Distinct().CountAsync();
            var workerCount = await _db.Workers.CountAsync();
            var totalUsers = activeUsers + deletedUsers;
            var normalUserCount = totalUsers - ownerCount - workerCount;

            var categoryGroups = await _db.Locales
                .Where(l => !l.IsDeleted)
                .GroupBy(l => l.CategoryId)
                .Select(g => new { CategoryId = g.Key, Count = g.Count() })
                .OrderBy(x => x.CategoryId)
                .Take(3)
                .ToListAsync();
            var categoryCounts = new int[3];
            for (var i = 0; i < categoryGroups.Count; i++)
                categoryCounts[i] = categoryGroups[i].Count;

            var topCountries = await _db.Locales
                .Where(l => !l.IsDeleted)
                .GroupBy(l => new { l.City.CountryId, CountryName = l.City.Country.Name })
                .Select(g => new { g.Key.CountryId, g.Key.CountryName, Count = g.Count() })
                .OrderByDescending(x => x.Count)
                .ThenBy(x => x.CountryId)
                .ToListAsync();

            return new AdminAnalyticsResponse
            {
                UserStatsData = new[] { activeUsers, deletedUsers },
                UserRoleData = new[] { ownerCount, workerCount, normalUserCount },
                LocaleCategoryData = categoryCounts,
                LocaleCountyData = topCountries.Select(x => x.Count).ToArray(),
                CountyNames = topCountries.Select(x => x.CountryName).ToArray()
            };
        }

        public async Task<AdminStatsResponse> GetStats()
        {

            var stats = new AdminStatsResponse
            {
                CountOfUsers = await _db.Users.CountAsync(),
                CountOfDeletedUsers = await _db.Users.CountAsync(u => u.IsDeleted),
                CountOfActiveUsers = await _db.Users.CountAsync(u => !u.IsDeleted),
                CountOfLocales = await _db.Locales.CountAsync(l => !l.IsDeleted),
                CountOfActiveReservations = await _db.Reservations.CountAsync(x => x.ReservationState != "Otkazana"),
                CountOfPastReservations = await _db.Reservations.CountAsync(x => x.ReservationState == "Otkazana"),
                CountOfCountries = await _db.Countries.CountAsync(),
                CountOfCities = await _db.Countries.CountAsync(),
                CountOfCategories = await _db.Categories.CountAsync(),
            };

            return stats;
        }

        public async Task ReactivateLocale(int id)
        {
            _logger.LogInformation("Reactivating locale. LocaleId: {LocaleId}", id);
            var locale = await _db.Locales.FirstOrDefaultAsync(x => x.IsDeleted && x.Id == id);
            if (locale == null)
            {
                _logger.LogWarning("Cannot reactivate locale because it was not found. LocaleId: {LocaleId}", id);
                throw new UserException("Lokal nije pronađen!");
            }

            locale.IsDeleted = false;
            locale.DeletedAt = null;

            _db.Locales.Update(locale);
            await _db.SaveChangesAsync();
            _logger.LogInformation("Locale reactivated successfully. LocaleId: {LocaleId}", id);
        }

        public async Task UpdateLocale(int id, AdminUpdateLocaleRequest request)
        {
            _logger.LogInformation("Updating locale through admin panel. LocaleId: {LocaleId}", id);
            var locale = await _db.Locales.FirstOrDefaultAsync(x => x.Id == id);
            if (locale == null)
            {
                _logger.LogWarning("Cannot update locale because it was not found. LocaleId: {LocaleId}", id);
                throw new UserException($"Lokal sa ID {id} nije pronađen!");
            }

            locale.Name = request.LocaleName;
            locale.CityId = request.CityId;
            locale.Address = request.Address;
            locale.CategoryId = request.CategoryId;

            await _db.SaveChangesAsync();
            _logger.LogInformation("Locale updated successfully. LocaleId: {LocaleId}", id);
        }
    }
}
