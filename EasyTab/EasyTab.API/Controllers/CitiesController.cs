using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CitiesController : BaseCRUDController<Cities, CitySearchObject, CityInsertRequest, CityUpdateRequest>
    {
        public CitiesController(ICityService service) : base(service) { }
    }
}
