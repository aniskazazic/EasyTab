using EasyTab.API.Services.AccessManager;
using EasyTab.Model.Access;
using EasyTab.Model.Requests;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class AccessController : ControllerBase
    {
        private readonly IAccessManager _accessManager;
        private readonly IUserService _userService;
        public AccessController(IAccessManager accessManager, IUserService userService)
        {
            _accessManager = accessManager;
            _userService = userService;
        }

        [HttpPost("Login")]
        [AllowAnonymous]
        public async Task<ActionResult> Login([FromBody] UserLoginRequest request)
        {
            var result = await _accessManager.LoginAsync(request);
            return Ok(result);
        }

        [HttpPost("LoginWithRefreshToken")]
        [AllowAnonymous]
        public async Task<ActionResult> LoginWithRefreshToken([FromBody] RefreshAccessTokenRequest request)
        {
            var result = await _accessManager.LoginWithRefreshTokenAsync(request);
            return Ok(result);
        }

        [HttpPost("Register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register([FromBody] UserRegisterRequest request)
        {
            await _userService.RegisterAsync(request);
            return Ok("Registracija uspješno izvršena !");
        }
    }
}
