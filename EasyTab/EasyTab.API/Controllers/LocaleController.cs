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
    [Authorization("Admin", "Vlasnik")]
    public class LocaleController :BaseCRUDController<Locales, LocaleSearchObject, LocaleInsertRequest, LocaleUpdateRequest>
    {
            public LocaleController(ILocaleService service) : base(service) {  }

    }
}
