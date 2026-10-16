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


        public async Task DeleteAllUserRefreshTokensAsync(int userId)
        {
            var userTokens = await _refreshTokens
                .Where(rt => rt.UserId == userId)
                .ToListAsync();

            _refreshTokens.RemoveRange(userTokens);
            await _context.SaveChangesAsync();
        }

        public async Task<RefreshToken?> GetStoredTokenAsync(string refreshToken)
        {
            return await _refreshTokens.FirstOrDefaultAsync(rt => rt.Token == refreshToken);
        }

        public async Task ReplaceUserRefreshTokenAsync(int userId, RefreshToken refreshToken)
        {
            var existingTokens = await _refreshTokens
                .Where(token => token.UserId == userId)
                .ToListAsync();

            _refreshTokens.RemoveRange(existingTokens);
            await _refreshTokens.AddAsync(refreshToken);
            await _context.SaveChangesAsync();
        }
    }
}
