using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;


namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : BaseCRUDController<Users, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        public UsersController(IUserService service) : base(service) { }

        [HttpPost("login")]
        [AllowAnonymous]
        public Users Login(string username, string password)
        {
            return (_service as IUserService).Login(username, password);
        }

    }
}
