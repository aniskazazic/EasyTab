using EasyTab.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IRefreshTokenService
    {
        Task<RefreshToken?> GetStoredTokenAsync(string refreshToken);
        Task CreateSessionAsync(RefreshToken refreshToken);
        Task<bool> RotateSessionAsync(int sessionId, int userId, string previousToken, string token, DateTime expiresAt);
        Task<bool> IsSessionActiveAsync(int sessionId, int userId, CancellationToken cancellationToken = default);
        Task RevokeSessionAsync(int sessionId, int userId);
    }
}
