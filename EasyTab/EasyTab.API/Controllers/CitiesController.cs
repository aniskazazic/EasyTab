using EasyTab.API.Controllers.BaseControllers;
using EasyTab.API.Filters;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization]
    public class CitiesController : BaseCRUDController<Cities, CitySearchObject, CityInsertRequest, CityUpdateRequest>
    {
        public CitiesController(ICityService service) : base(service) { }

        [Authorization("Admin")]
        public override Task<Cities> Create([FromBody] CityInsertRequest request) => base.Create(request);

        [Authorization("Admin")]
        public override Task<Cities?> Update(int id, [FromBody] CityUpdateRequest request) => base.Update(id, request);

        [Authorization("Admin")]
        public override Task<bool> Delete(int id) => base.Delete(id);
    }
}
