using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services;
using EasyTab.Services.BaseServices.Implementation;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CountriesController : BaseCRUDController<Countries, CountrySearchObject, CountryInsertRequest, CountryUpdateRequest>
    {
        public CountriesController(ICountryService service) : base(service) { }
    }
}
