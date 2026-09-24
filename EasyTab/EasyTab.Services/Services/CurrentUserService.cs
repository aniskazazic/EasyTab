using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using System.Security.Claims;

namespace EasyTab.Services.Services
{
    public class CurrentUserService : ICurrentUserService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;

        public CurrentUserService(IHttpContextAccessor httpContextAccessor)
        {
            _httpContextAccessor = httpContextAccessor;
        }

        public int UserId
        {
            get
            {
                var value = _httpContextAccessor.HttpContext?.User.FindFirst("Id")?.Value
                    ?? _httpContextAccessor.HttpContext?.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

                if (!int.TryParse(value, out var userId))
                    throw new UnauthorizedAccessException("Korisnički identitet nije pronađen u tokenu.");

                return userId;
            }
        }

        public string? Role => _httpContextAccessor.HttpContext?.User.FindFirst("Role")?.Value
            ?? _httpContextAccessor.HttpContext?.User.FindFirst(ClaimTypes.Role)?.Value;

        public bool IsAdmin => string.Equals(Role, "Admin", StringComparison.Ordinal);
    }
}
