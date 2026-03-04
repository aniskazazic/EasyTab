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
    public class ZonesController : BaseCRUDController<Zones, ZoneSearchObject, ZoneInsertRequest, ZoneUpdateRequest>
    {
        public IZoneService _service;
        public ZonesController(IZoneService service) : base(service) 
        { 
            _service = service; 
        }

        [HttpPost("save-layout")]
        public IActionResult SaveLayout([FromBody] ZoneLayoutRequest request)
        {
            _service.SaveLayout(request);
            return Ok(new { Message = "Zones saved" });
        }

    }
}
