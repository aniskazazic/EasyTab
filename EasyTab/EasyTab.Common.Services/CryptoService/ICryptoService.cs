using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Common.Services.CryptoService
{
    public interface ICryptoService 
    {
        string GenerateHash(string password, string salt);
        string GenerateSalt();
        bool Verify(string hash, string salt, string password);
    }
}
