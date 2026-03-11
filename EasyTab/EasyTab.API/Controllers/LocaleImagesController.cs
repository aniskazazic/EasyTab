using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Interfaces;
using EasyTab.Services.Interfaces;
using EasyTab.Services.Services;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class LocaleImagesController : BaseController<LocaleImages, LocaleImageSearchObject>
    {
        public ILocaleImageService _service;

        public LocaleImagesController(ILocaleImageService service) : base(service)
        {
            _service = service;
        }
        [HttpPost]
        public IActionResult Insert([FromBody] LocaleImageInsertRequest request)
        {
            var result = _service.Insert(request);
            return Ok(result);
        }

        [HttpDelete("{id}")]
        public IActionResult Delete(int id)
        {
            _service.Delete(id);
            return Ok(new { Message = "Slika obrisana!" });
        }

        [HttpGet("by-locale/{localeId}")]
        public IActionResult GetByLocale(int localeId)
        {
            var result = _service.GetByLocale(localeId);
            return Ok(result);
        }
    }
}
