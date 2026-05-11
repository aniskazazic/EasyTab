using Azure.Core;
using EasyTab.API.Controllers.BaseControllers;
using EasyTab.API.Filters;
using EasyTab.Model;
using EasyTab.Model.Access;
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

        [Authorization("Admin")]
        public override Task<PagedResult<Users>> Get([FromQuery] UserSearchObject? search = null)
        {
            return base.Get(search);
        }

        [AllowAnonymous]
        public override Task<Users> Create([FromBody] UserInsertRequest request)
        {
            return base.Create(request);
        }

        [HttpPut("ChangePassword")]
        public async Task<IActionResult> ChangePassword([FromBody] UserPasswordChangeRequest request)
        {
            await _service.ChangePasswordAsync(request);
            return Ok();
        }
    }
}
