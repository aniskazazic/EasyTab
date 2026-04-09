using Azure.Core;
using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;
using EasyTab.Services.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;


namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : BaseCRUDController<Users, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        private readonly IUserService _service;
        public UsersController(IUserService service) : base(service) { _service = service; }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<ActionResult<Users>> Login(UserLoginRequest request)
        {
            var user = await _service.AuthenticateAsync(request);
            return Ok(user);
        }

        [AllowAnonymous]
        public override Task<Users> Create([FromBody] UserInsertRequest request)
        {
            return base.Create(request);
        }


    }
}
