using Azure.Core;
using EasyTab.Common.Services.CryptoService;
using EasyTab.Model.Access;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Models;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace EasyTab.API.Services.AccessManager
{
    public class AccessManager : IAccessManager
    {
        private readonly IUserService _userService;
        private readonly IConfiguration _configuration;
        private readonly ICryptoService _cryptoService;
        private readonly IRefreshTokenService _refreshTokenService;

        public AccessManager(IUserService userService, IConfiguration configuration, ICryptoService cryptoService, IRefreshTokenService refreshTokenService)
        {
            _userService = userService;
            _configuration = configuration;
            _cryptoService = cryptoService;
            _refreshTokenService = refreshTokenService;
        }
        public async Task<UserLoginResponse> LoginAsync(UserLoginRequest request)
        {
            var user = await _userService.GetByUsernameAsync(request.Username);

            if (user == null)
            {
                throw new UserException($"Korisnik sa korisničkim imenom {request.Username} ne postoji!");
            }

            var validPassword = _cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password);

            if (!validPassword)
            {
                throw new UserException("Pogrešni kredencijali !");
            }

            var accessToken = GenerateToken(user);

            var refreshTokenValue = GenerateRefreshToken();

            var refreshToken = new RefreshToken
            {
                Token = refreshTokenValue,
                UserId = user.Id,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            };

            await _refreshTokenService.InsertAsync(refreshToken);

            return new UserLoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshTokenValue
            };
        }

        private string GenerateToken(Users user)
        {
            string secretKeyString = _configuration["JwtToken:SecretKey"] ?? string.Empty;
            var issuer = _configuration["JwtToken:Issuer"];
            var audience = _configuration["JwtToken:Audience"];
            var durationInMinutes = int.Parse(_configuration["JwtToken:DurationInMinutes"] ?? "1");

            var secretKey = Encoding.ASCII.GetBytes(secretKeyString);

            var tokenDescriptor = new SecurityTokenDescriptor
            {
                Subject = new ClaimsIdentity(new[]
                {
                    new Claim(ClaimNames.Id, user.Id.ToString()),
                    new Claim(ClaimNames.FirstName, user.FirstName),
                    new Claim(ClaimNames.LastName, user.LastName),
                    new Claim(ClaimNames.Email, user.Email),
                    new Claim(ClaimNames.IsDeleted, user.IsDeleted.ToString())
                }),
                Expires = DateTime.UtcNow.AddMinutes(durationInMinutes),
                Issuer = issuer,
                Audience = audience,
                SigningCredentials = new SigningCredentials(new SymmetricSecurityKey(secretKey), SecurityAlgorithms.HmacSha256Signature)
            };

            var tokenHandler = new JwtSecurityTokenHandler();

            var token = tokenHandler.CreateToken(tokenDescriptor);

            return tokenHandler.WriteToken(token);


        }

        private static string GenerateRefreshToken()
        {
            var randomBytes = RandomNumberGenerator.GetBytes(64);
            return Convert.ToBase64String(randomBytes);
        }

        public async Task<UserLoginResponse> LoginWithRefreshTokenAsync(RefreshAccessTokenRequest request)
        {
            if (string.IsNullOrEmpty(request.RefreshToken)) { 
                throw new UserException("Refresh token je obavezan!");
            }

            var refreshToken = await _refreshTokenService.GetStoredTokenAsync(request.RefreshToken);

            if (refreshToken == null)
            {
                throw new UserException("Refresh token nije validan!");
            }

            if (refreshToken.ExpiresAt < DateTime.UtcNow)
            {
                throw new UserException("Refresh token je istekao!");
            }

            var user = await _userService.GetByIdAsync(refreshToken.UserId);

            if (user == null)
            {
                throw new UserException("Korisnik nije pronađen!");
            }

            if (user.IsDeleted)
            {
                throw new UserException("Korisnik nije aktivan!");
            }

            await _refreshTokenService.DeleteAllUserRefreshTokensAsync(user.Id);

            var accessToken = GenerateToken(user);

            var refreshTokenValue = GenerateRefreshToken();

            var token = new RefreshToken
            {
                Token = refreshTokenValue,
                UserId = user.Id,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            };

            await _refreshTokenService.InsertAsync(token);

            return new UserLoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshTokenValue
            };
        }
    }
}
