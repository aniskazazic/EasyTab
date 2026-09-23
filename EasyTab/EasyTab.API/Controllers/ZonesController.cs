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
    public class ZonesController : BaseCRUDController<Zones, ZoneSearchObject, ZoneInsertRequest, ZoneUpdateRequest>
    {
        public IZoneService _service;
        public ZonesController(IZoneService service) : base(service) 
        { 
            _service = service; 
        }

        [Authorization("Admin", "Vlasnik", "Radnik")]
        public override Task<Zones> Create([FromBody] ZoneInsertRequest request) => base.Create(request);

        [Authorization("Admin", "Vlasnik", "Radnik")]
        public override Task<Zones?> Update(int id, [FromBody] ZoneUpdateRequest request) => base.Update(id, request);

        [Authorization("Admin", "Vlasnik", "Radnik")]
        public override Task<bool> Delete(int id) => base.Delete(id);


        [HttpPost("save-layout")]
        [Authorization("Admin", "Vlasnik")]
        public async Task<IActionResult> SaveLayout([FromBody] ZoneLayoutRequest request)
        {
            await _service.SaveLayoutAsync(request);
            return Ok(new { Message = "Zones saved" });
        }

    }
}
