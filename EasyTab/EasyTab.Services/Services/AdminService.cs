using EasyTab.Model;
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

        public async Task<AdminAnalyticsResponse> GetAnalytics()
        {
            var activeUsers = await _db.Users.CountAsync(u => !u.IsDeleted);
            var deletedUsers = await _db.Users.CountAsync(u => u.IsDeleted);
            var userRoleData = await GetUserRoleDataAsync();

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
                UserRoleData = userRoleData,
                UserRoleLabels = UserRoleLabels,
                LocaleCategoryData = categoryCounts,
                LocaleCountyData = topCountries.Select(x => x.Count).ToArray(),
                CountyNames = topCountries.Select(x => x.CountryName).ToArray()
            };
        }

        private static readonly string[] UserRoleLabels =
        {
            "Vlasnici (aktivna uloga Vlasnik, bez administratora)",
            "Radnici (aktivna uloga Radnik i aktivan angažman, bez administratora i vlasnika)",
            "Korisnici (ostali aktivni korisnici)",
            "Administratori (aktivna uloga Admin)"
        };

        private async Task<int[]> GetUserRoleDataAsync()
        {
            const int owner = 0, worker = 1, user = 2, admin = 3;

            var activeUserRoles = _db.UserRoles.Where(ur => !ur.IsDeleted && !ur.Role.IsDeleted);
            var activeWorkers = _db.Workers.Active();

            var groups = await _db.Users
                .Where(u => !u.IsDeleted)
                .Select(u => new
                {
                    IsAdmin = activeUserRoles.Any(ur => ur.UserId == u.Id && ur.Role.Name == RoleNames.Admin),
                    IsOwner = activeUserRoles.Any(ur => ur.UserId == u.Id && ur.Role.Name == RoleNames.Vlasnik),
                    IsWorker = activeUserRoles.Any(ur => ur.UserId == u.Id && ur.Role.Name == RoleNames.Radnik)
                        && activeWorkers.Any(w => w.UserId == u.Id)
                })
                .GroupBy(x => x.IsAdmin ? admin : x.IsOwner ? owner : x.IsWorker ? worker : user)
                .Select(g => new { Category = g.Key, Count = g.Count() })
                .ToListAsync();

            var result = new int[UserRoleLabels.Length];
            foreach (var group in groups)
                result[group.Category] = group.Count;
            return result;
        }

        public async Task ReactivateLocale(int id)
        {
            _logger.LogInformation("Reactivating locale. LocaleId: {LocaleId}", id);
            await using var transaction = await _db.Database.BeginTransactionAsync(CancellationToken.None);
            await ReservationOperationLock.LocaleAsync(_db, id);
            var locale = await _db.Locales.FirstOrDefaultAsync(x => x.IsDeleted && x.Id == id);
            if (locale == null)
            {
                _logger.LogWarning("Cannot reactivate locale because it was not found. LocaleId: {LocaleId}", id);
                throw new UserException("Lokal nije pronađen!");
            }

            await _db.Entry(locale).ReloadAsync(CancellationToken.None);
            locale.IsDeleted = false;
            locale.DeletedAt = null;

            _db.Locales.Update(locale);
            await _db.SaveChangesAsync();
            await transaction.CommitAsync(CancellationToken.None);
            _logger.LogInformation("Locale reactivated successfully. LocaleId: {LocaleId}", id);
        }
    }
}
