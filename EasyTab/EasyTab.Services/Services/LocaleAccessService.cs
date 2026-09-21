using EasyTab.Model.Exceptions;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace EasyTab.Services.Services
{
    public class LocaleAccessService : ILocaleAccessService
    {
        private readonly _220030Context _context;
        private readonly IHttpContextAccessor _httpContextAccessor;

        public LocaleAccessService(_220030Context context, IHttpContextAccessor httpContextAccessor)
        {
            _context = context;
            _httpContextAccessor = httpContextAccessor;
        }

        public Task EnsureCanManageLocaleAsync(int localeId)
        {
            return EnsureAccessAsync(localeId, allowWorker: true);
        }

        public Task EnsureCanManageLocaleAsOwnerAsync(int localeId)
        {
            return EnsureAccessAsync(localeId, allowWorker: false);
        }

        private async Task EnsureAccessAsync(int localeId, bool allowWorker)
        {
            var user = _httpContextAccessor.HttpContext?.User;
            var userIdValue = user?.FindFirst("Id")?.Value
                ?? user?.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (!int.TryParse(userIdValue, out var userId))
                throw new UnauthorizedAccessException("Korisnički identitet nije pronađen u tokenu.");

            var role = user?.FindFirst("Role")?.Value
                ?? user?.FindFirst(ClaimTypes.Role)?.Value;

            if (role == "Admin")
                return;

            var isOwner = role == "Vlasnik" && await _context.Locales
                .AnyAsync(locale => locale.Id == localeId && locale.OwnerId == userId);

            var isWorker = allowWorker && role == "Radnik" && await _context.Workers
                .AnyAsync(worker => worker.LocaleId == localeId && worker.UserId == userId && !worker.IsDeleted);

            if (!isOwner && !isWorker)
                throw new UserException("Nemate dozvolu za upravljanje ovim lokalom.");
        }
    }
}
