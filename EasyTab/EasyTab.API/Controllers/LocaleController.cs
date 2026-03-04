using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;

namespace EasyTab.API.Controllers
{
    public class LocaleController :BaseCRUDController<Locales, LocaleSearchObject, LocaleInsertRequest, LocaleUpdateRequest>
    {
            public LocaleController(ILocaleService service) : base(service) {  }

    }
}
