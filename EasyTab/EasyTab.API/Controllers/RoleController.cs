using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;

namespace EasyTab.API.Controllers
{
    public class RoleController : BaseCRUDController<Roles, RoleSearchObject, RoleInsertRequest, RoleUpdateRequest>
    {
        public RoleController(IRoleService service) : base(service)
        {

        }
    }
}
