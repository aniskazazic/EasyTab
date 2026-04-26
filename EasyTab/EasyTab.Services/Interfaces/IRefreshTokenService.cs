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
        Task<RefreshToken> GetStoredTokenAsync(string refreshToken);
        Task InsertAsync(RefreshToken refreshToken);
        Task DeleteAllUserRefreshTokensAsync(int userId);
    }
}
