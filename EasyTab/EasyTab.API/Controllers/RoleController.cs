using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.API.Filters;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization("Admin")]
    public class RoleController : BaseCRUDController<Roles, RoleSearchObject, RoleInsertRequest, RoleUpdateRequest>
    {
        public RoleController(IRoleService service) : base(service)
        {

        }
    }
}
