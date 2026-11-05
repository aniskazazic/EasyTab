using EasyTab.Common.Services.CryptoService;
using EasyTab.Model.Access;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Models;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
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
        private readonly IValidator<UserLoginRequest> _loginValidator;
        private readonly ICurrentUserService _currentUser;

        public AccessManager(IUserService userService, IConfiguration configuration, ICryptoService cryptoService, IRefreshTokenService refreshTokenService, IValidator<UserLoginRequest> loginValidator, ICurrentUserService currentUser)
        {
            _userService = userService;
            _configuration = configuration;
            _cryptoService = cryptoService;
            _refreshTokenService = refreshTokenService;
            _loginValidator = loginValidator;
            _currentUser = currentUser;
        }
        public async Task<UserLoginResponse> LoginAsync(UserLoginRequest request)
        {
            await _loginValidator.ValidateAndThrowAsync(request);

            if (string.IsNullOrWhiteSpace(request.Username) || string.IsNullOrEmpty(request.Password))
            {
                throw new UserException("Pogrešno korisničko ime ili lozinka.");
            }

            var user = await _userService.GetByUsernameAsync(request.Username);

            if (user == null || user.IsDeleted || !_cryptoService.Verify(user.PasswordHash, user.PasswordSalt, request.Password))
            {
                throw new UserException("Pogrešno korisničko ime ili lozinka.");
            }

            var refreshTokenValue = GenerateRefreshToken();

            var refreshToken = new RefreshToken
            {
                Token = refreshTokenValue,
                UserId = user.Id,
                ExpiresAt = DateTime.UtcNow.AddDays(7)
            };

            await _refreshTokenService.CreateSessionAsync(refreshToken);
            var accessToken = GenerateToken(user, refreshToken.Id);

            return new UserLoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshTokenValue
            };
        }

        private string GenerateToken(Users user, int sessionId)
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
                    new Claim("sid", sessionId.ToString()),
                    new Claim(ClaimNames.FirstName, user.FirstName),
                    new Claim(ClaimNames.LastName, user.LastName),
                    new Claim(ClaimNames.Email, user.Email),
                    new Claim(ClaimNames.Role, user.Role),
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
                throw new InvalidRefreshTokenException("Refresh token je obavezan!");
            }

            var refreshToken = await _refreshTokenService.GetStoredTokenAsync(request.RefreshToken);

            if (refreshToken == null)
            {
                throw new InvalidRefreshTokenException("Refresh token nije validan!");
            }

            if (refreshToken.ExpiresAt <= DateTime.UtcNow)
            {
                throw new InvalidRefreshTokenException("Refresh token je istekao!");
            }

            var user = await _userService.GetWithRoleByIdAsync(refreshToken.UserId);

            if (user == null)
            {
                throw new UserException("Korisnik nije pronađen!");
            }

            if (user.IsDeleted)
            {
                throw new UserException("Korisnik nije aktivan!");
            }

            var refreshTokenValue = GenerateRefreshToken();
            var rotated = await _refreshTokenService.RotateSessionAsync(
                refreshToken.Id, user.Id, request.RefreshToken, refreshTokenValue, DateTime.UtcNow.AddDays(7));
            if (!rotated)
            {
                throw new InvalidRefreshTokenException("Refresh token više nije validan.");
            }
            var accessToken = GenerateToken(user, refreshToken.Id);

            return new UserLoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshTokenValue
            };
        }

        public Task LogoutAsync()
        {
            return _refreshTokenService.RevokeSessionAsync(_currentUser.SessionId, _currentUser.UserId);
        }
    }
}
