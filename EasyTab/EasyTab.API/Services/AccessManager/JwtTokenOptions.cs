using Microsoft.IdentityModel.Tokens;
using System.Text;

namespace EasyTab.API.Services.AccessManager
{
    public class JwtTokenOptions
    {
        public const string SectionName = "JwtToken";

        // HMAC-SHA256 traži ključ od najmanje 256 bita.
        public const int MinimumSecretKeyBytes = 32;

        public string SecretKey { get; set; } = string.Empty;
        public string Issuer { get; set; } = string.Empty;
        public string Audience { get; set; } = string.Empty;
        public int DurationInMinutes { get; set; }

        // Isti UTF-8 ključ potpisuje token (AccessManager) i provjerava ga (JwtBearer u Program.cs).
        public SymmetricSecurityKey GetSigningKey() => new(Encoding.UTF8.GetBytes(SecretKey));
    }
}
