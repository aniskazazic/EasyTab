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
    public class LocaleController :BaseCRUDController<Locales, LocaleSearchObject, LocaleInsertRequest, LocaleUpdateRequest>
    {
            public LocaleController(ILocaleService service) : base(service) {  }

        [Authorization("Admin", "Vlasnik")]
        public override Task<Locales> Create([FromBody] LocaleInsertRequest request) => base.Create(request);

        [Authorization("Admin", "Vlasnik")]
        public override Task<Locales?> Update(int id, [FromBody] LocaleUpdateRequest request) => base.Update(id, request);

        [Authorization("Admin", "Vlasnik")]
        public override Task<bool> Delete(int id) => base.Delete(id);

    }
}
