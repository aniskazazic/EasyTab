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
    public class LocaleImagesController : BaseCRUDController<LocaleImages, LocaleImageSearchObject, LocaleImageInsertRequest, LocaleImageUpdateRequest>
    {
        public LocaleImagesController(ILocaleImageService service) : base(service)
        {
        }

        [Authorization("Admin", "Vlasnik")]
        public override Task<LocaleImages> Create([FromBody] LocaleImageInsertRequest request) => base.Create(request);

        [Authorization("Admin", "Vlasnik")]
        public override Task<LocaleImages?> Update(int id, [FromBody] LocaleImageUpdateRequest request) => base.Update(id, request);

        [Authorization("Admin", "Vlasnik")]
        public override Task<bool> Delete(int id) => base.Delete(id);
    }
}
