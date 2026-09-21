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
    public class ZonesController : BaseCRUDController<Zones, ZoneSearchObject, ZoneInsertRequest, ZoneUpdateRequest>
    {
        public IZoneService _service;
        public ZonesController(IZoneService service) : base(service) 
        { 
            _service = service; 
        }


        [HttpPost("save-layout")]
        [Authorization("Admin", "Vlasnik", "Radnik")]
        public async Task<IActionResult> SaveLayout([FromBody] ZoneLayoutRequest request)
        {
            await _service.SaveLayoutAsync(request);
            return Ok(new { Message = "Zones saved" });
        }

    }
}
