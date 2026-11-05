using System.Security.Claims;

namespace EasyTab.Services.Interfaces
{
    public interface ICurrentUserService
    {
        int UserId { get; }
        int SessionId { get; }
        (int UserId, int SessionId)? GetSession(ClaimsPrincipal? principal);
        string? Role { get; }
        bool IsAdmin { get; }
    }
}
