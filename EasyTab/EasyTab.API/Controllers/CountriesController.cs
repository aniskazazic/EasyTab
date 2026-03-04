using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CountriesController : BaseCRUDController<Countries, CountrySearchObject, CountryUpsertRequest, CountryUpsertRequest>
    {
        public CountriesController(ICountryService service) : base(service) { }
    }
}
