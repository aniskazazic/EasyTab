using EasyTab.Model;
using EasyTab.Serivces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CountriesController : ControllerBase
    {
        protected ICountryService _service;

        public CountriesController(CountryService service)
        {
            _service = service;
        }

        [HttpGet]
        public List<Countries> GetCountries()
        {
            return _service.GetCountries();
        }
    }
}
