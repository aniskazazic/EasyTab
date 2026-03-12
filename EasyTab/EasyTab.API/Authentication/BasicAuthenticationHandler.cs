using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Net.Http.Headers;
using System.Security.Claims;
using System.Text;
using System.Text.Encodings.Web;

namespace EasyTab.API.Authentication
{
    public class BasicAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        IUserService _userService;
        public BasicAuthenticationHandler(IOptionsMonitor<AuthenticationSchemeOptions> options, ILoggerFactory logger, UrlEncoder encoder, ISystemClock clock, IUserService userService) : base(options, logger, encoder, clock)
        {
            _userService = userService;
        }

        protected override async Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            if (!Request.Headers.ContainsKey("Authorization"))
                return AuthenticateResult.NoResult();

            var authHeader = AuthenticationHeaderValue.Parse(Request.Headers["Authorization"]);
            var credentialBytes = Convert.FromBase64String(authHeader.Parameter!);
            var credentials = Encoding.UTF8.GetString(credentialBytes).Split(':');
            var username = credentials[0];
            var password = credentials[1];

            // Koristimo AuthenticateAsync kao profesor
            var user = await _userService.AuthenticateAsync(new UserLoginRequest
            {
                Username = username,
                Password = password
            });

            if (user == null)
                return AuthenticateResult.Fail("Invalid credentials");

            // Claims kao kod profesora + Id kao NameIdentifier
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Name, user.Username),
                new Claim(ClaimTypes.GivenName, user.FirstName),
                new Claim(ClaimTypes.Surname, user.LastName),
                new Claim(ClaimTypes.Email, user.Email)
            };

            // Dodaj role iz UserRoles
            if (user.UserRoles != null)
            {
                foreach (var userRole in user.UserRoles)
                {
                    if (userRole.Role != null)
                        claims.Add(new Claim(ClaimTypes.Role, userRole.Role.Name));
                }
            }

            var identity = new ClaimsIdentity(claims, Scheme.Name);
            var principal = new ClaimsPrincipal(identity);
            var ticket = new AuthenticationTicket(principal, Scheme.Name);

            return AuthenticateResult.Success(ticket);
        }
    }
}