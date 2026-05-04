using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class LocaleImagesController : BaseCRUDController<LocaleImages, LocaleImageSearchObject, LocaleImageInsertRequest, LocaleImageUpdateRequest>
    {
        public LocaleImagesController(ILocaleImageService service) : base(service)
        {
        }
    }
}
