using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Services;
using Microsoft.AspNetCore.Mvc;


namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class UsersController : ControllerBase
    {
        protected IUsersService _service { get; set; }
        public UsersController(IUsersService service)
        {
            _service = service;
        }

        [HttpGet]
        public List<Users> GetUsers()
        {
            return _service.GetUsers();
        }

        [HttpPost]
        public Users Insert(UserInsertRequest request)
        {
            return _service.Insert(request);
        }

        [HttpPut]
        public Users Update(int id, UserUpdateRequest request)
        { 
            return _service.Update(id, request);
        }

    }
}
