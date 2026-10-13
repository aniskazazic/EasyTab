using EasyTab.API.Controllers.BaseControllers;
using EasyTab.API.Filters;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using EasyTab.Model;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization]
    public class WorkersController : BaseCRUDController<Workers, WorkerSearchObject, WorkerInsertRequest, WorkerUpdateRequest>
    {
        public WorkersController(IWorkerService service) : base(service) {  }

        [Authorization(RoleNames.Admin, RoleNames.Vlasnik)]
        public override Task<Workers> Create([FromBody] WorkerInsertRequest request) => base.Create(request);

        [Authorization(RoleNames.Admin, RoleNames.Vlasnik)]
        public override Task<Workers?> Update(int id, [FromBody] WorkerUpdateRequest request) => base.Update(id, request);

        [Authorization(RoleNames.Admin, RoleNames.Vlasnik)]
        public override Task<bool> Delete(int id) => base.Delete(id);

    }
}
