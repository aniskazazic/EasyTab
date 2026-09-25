using EasyTab.API.Controllers.BaseControllers;
using EasyTab.API.Filters;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;
using EasyTab.Services.Services;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization]
    public class TablesController : BaseCRUDController<Tables, TableSearchObject, TableInsertRequest, TableUpdateRequest>
    {
        public ITableService _service;
        public TablesController(ITableService service) : base(service)
        {
            _service = service;
        }

        [Authorization("Admin", "Vlasnik")]
        public override Task<Tables> Create([FromBody] TableInsertRequest request) => base.Create(request);

        [Authorization("Admin", "Vlasnik")]
        public override Task<Tables?> Update(int id, [FromBody] TableUpdateRequest request) => base.Update(id, request);

        [Authorization("Admin", "Vlasnik")]
        public override Task<bool> Delete(int id) => base.Delete(id);

        [HttpPost("save-layout")]
        [Authorization("Admin", "Vlasnik")]
        public async Task<IActionResult> SaveLayout([FromBody] TableLayoutRequest request)
        {
            await _service.SaveLayoutAsync(request);
            return Ok(new { Message = "Tables saved" });
        }
    }
}

