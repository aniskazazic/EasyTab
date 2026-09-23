using EasyTab.API.Controllers.BaseControllers;
using EasyTab.API.Filters;
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
    [Authorization]
    public class CountriesController : BaseCRUDController<Countries, CountrySearchObject, CountryUpsertRequest, CountryUpsertRequest>
    {
        public CountriesController(ICountryService service) : base(service) { }

        [Authorization("Admin")]
        public override Task<Countries> Create([FromBody] CountryUpsertRequest request) => base.Create(request);

        [Authorization("Admin")]
        public override Task<Countries?> Update(int id, [FromBody] CountryUpsertRequest request) => base.Update(id, request);

        [Authorization("Admin")]
        public override Task<bool> Delete(int id) => base.Delete(id);
    }
}
