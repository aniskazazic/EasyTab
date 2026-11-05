using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using System.Security.Claims;
using EasyTab.Model;

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

        public int SessionId => GetSession(_httpContextAccessor.HttpContext?.User)?.SessionId
            ?? throw new UnauthorizedAccessException("Sesija nije pronađena u tokenu.");

        public (int UserId, int SessionId)? GetSession(ClaimsPrincipal? principal)
        {
            var userIdClaim = principal?.FindFirst("Id")?.Value
                ?? principal?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            var sessionIdClaim = principal?.FindFirst("sid")?.Value
                ?? principal?.FindFirst(ClaimTypes.Sid)?.Value;

            return int.TryParse(userIdClaim, out var userId) && userId > 0 &&
                int.TryParse(sessionIdClaim, out var sessionId) && sessionId > 0
                    ? (userId, sessionId)
                    : null;
        }

        public string? Role => _httpContextAccessor.HttpContext?.User.FindFirst("Role")?.Value
            ?? _httpContextAccessor.HttpContext?.User.FindFirst(ClaimTypes.Role)?.Value;

        public bool IsAdmin => _httpContextAccessor.HttpContext?.User.Claims
            .Any(c => (c.Type == "Role" || c.Type == ClaimTypes.Role) && c.Value == RoleNames.Admin) ?? false;
    }
}
