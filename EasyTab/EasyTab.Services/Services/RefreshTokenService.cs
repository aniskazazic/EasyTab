using EasyTab.Model.Exceptions;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
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


        public Task DeleteAllUserRefreshTokensAsync(int userId)
        {
            _refreshTokens.RemoveRange(_refreshTokens.Where(rt => rt.UserId == userId));
            return _context.SaveChangesAsync(); ;
        }

        public async Task<RefreshToken> GetStoredTokenAsync(string refreshToken)
        {
            var token = await _refreshTokens.FirstOrDefaultAsync(rt => rt.Token == refreshToken);

            if (token == null) {
                throw new UserException("Refresh token nije pronađen.");
            }

            return token;
        }

        public async Task InsertAsync(RefreshToken refreshToken)
        {
            await _refreshTokens.AddAsync(refreshToken);
            await _context.SaveChangesAsync();
        }
    }
}
