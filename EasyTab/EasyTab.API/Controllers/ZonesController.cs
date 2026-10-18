using EasyTab.API.Controllers.BaseControllers;
using EasyTab.API.Filters;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using EasyTab.Model;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization]
    public class ZonesController : BaseCRUDController<Zones, ZoneSearchObject, ZoneInsertRequest, ZoneUpdateRequest>
    {
        private readonly IZoneService _zoneService;
        public ZonesController(IZoneService service) : base(service) 
        { 
            _zoneService = service;
        }

        [Authorization(RoleNames.Admin, RoleNames.Vlasnik)]
        public override Task<Zones> Create([FromBody] ZoneInsertRequest request) => base.Create(request);

        [Authorization(RoleNames.Admin, RoleNames.Vlasnik)]
        public override Task<Zones?> Update(int id, [FromBody] ZoneUpdateRequest request) => base.Update(id, request);

        [Authorization(RoleNames.Admin, RoleNames.Vlasnik)]
        public override Task<bool> Delete(int id) => base.Delete(id);


        [HttpPost("save-layout")]
        [Authorization(RoleNames.Admin, RoleNames.Vlasnik)]
        public async Task<IActionResult> SaveLayout([FromBody] ZoneLayoutRequest request)
        {
            await _zoneService.SaveLayoutAsync(request);
            return Ok(new { Message = "Zones saved" });
        }

    }
}
