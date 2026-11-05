using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.Linq;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class RefreshTokenService : IRefreshTokenService
    {
        private readonly _220030Context _context;
        private readonly DbSet<RefreshToken> _refreshTokens;

        public RefreshTokenService(_220030Context context)
        {
            _context = context;
            _refreshTokens = _context.RefreshTokens;
        }


        public async Task RevokeSessionAsync(int sessionId, int userId)
        {
            await _refreshTokens.Where(token => token.Id == sessionId && token.UserId == userId)
                .ExecuteDeleteAsync();
        }

        public async Task<RefreshToken?> GetStoredTokenAsync(string refreshToken)
        {
            return await _refreshTokens.AsNoTracking().FirstOrDefaultAsync(rt => rt.Token == refreshToken);
        }

        public async Task CreateSessionAsync(RefreshToken refreshToken)
        {
            await _refreshTokens.AddAsync(refreshToken);
            await _context.SaveChangesAsync();
        }

        public async Task<bool> RotateSessionAsync(int sessionId, int userId, string previousToken, string token, DateTime expiresAt)
        {
            var now = DateTime.UtcNow;
            var updated = await _refreshTokens
                .Where(session => session.Id == sessionId && session.UserId == userId &&
                    session.Token == previousToken && session.ExpiresAt > now && !session.User.IsDeleted)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(session => session.Token, token)
                    .SetProperty(session => session.ExpiresAt, expiresAt));
            return updated == 1;
        }

        public Task<bool> IsSessionActiveAsync(int sessionId, int userId, CancellationToken cancellationToken = default)
        {
            var now = DateTime.UtcNow;
            return _refreshTokens.AnyAsync(session => session.Id == sessionId && session.UserId == userId &&
                session.ExpiresAt > now && !session.User.IsDeleted, cancellationToken);
        }
    }
}
