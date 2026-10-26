using EasyTab.Model.Exceptions;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using EasyTab.Model;

namespace EasyTab.Services.Services
{
    public class LocaleAccessService : ILocaleAccessService
    {
        private readonly _220030Context _context;
        private readonly ICurrentUserService _currentUser;

        public LocaleAccessService(_220030Context context, ICurrentUserService currentUser)
        {
            _context = context;
            _currentUser = currentUser;
        }

        public Task EnsureCanManageLocaleAsync(int localeId)
        {
            return EnsureAccessAsync(localeId, allowWorker: true);
        }

        public IQueryable<int> GetAccessibleLocaleIds()
        {
            var locales = _context.Locales.AsNoTracking();
            if (_currentUser.IsAdmin)
                return locales.Select(locale => locale.Id);

            var userId = _currentUser.UserId;
            return locales.Where(locale =>
                (_currentUser.Role == RoleNames.Vlasnik && locale.OwnerId == userId) ||
                (_currentUser.Role == RoleNames.Radnik && locale.Workers.Any(worker =>
                    worker.UserId == userId && !worker.IsDeleted)))
                .Select(locale => locale.Id);
        }

        public Task EnsureCanManageLocaleAsOwnerAsync(int localeId)
        {
            return EnsureAccessAsync(localeId, allowWorker: false);
        }

        public async Task<List<int>> GetLocaleManagerUserIdsAsync(int localeId)
        {
            var locale = await _context.Locales
                .AsNoTracking()
                .Include(x => x.Workers)
                .FirstOrDefaultAsync(x => x.Id == localeId);

            if (locale == null)
                return new List<int>();

            return new[] { locale.OwnerId }
                .Concat(locale.Workers
                    .Where(x => !x.IsDeleted)
                    .Select(x => x.UserId))
                .Distinct()
                .ToList();
        }

        private async Task EnsureAccessAsync(int localeId, bool allowWorker)
        {
            var userId = _currentUser.UserId;
            var role = _currentUser.Role;

            if (_currentUser.IsAdmin)
                return;

            var isOwner = role == RoleNames.Vlasnik && await _context.Locales
                .AnyAsync(locale => locale.Id == localeId && locale.OwnerId == userId);

            var isWorker = allowWorker && role == RoleNames.Radnik && await _context.Workers
                .AnyAsync(worker => worker.LocaleId == localeId && worker.UserId == userId && !worker.IsDeleted);

            if (!isOwner && !isWorker)
                throw new ForbiddenException("Nemate dozvolu za upravljanje ovim lokalom.");
        }
    }
}
