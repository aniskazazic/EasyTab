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
    [Authorization("Admin", "Vlasnik")]
    public class TablesController : BaseCRUDController<Tables, TableSearchObject, TableInsertRequest, TableUpdateRequest>
    {
        public ITableService _service;
        public TablesController(ITableService service) : base(service)
        {
            _service = service;
        }

        [HttpPost("save-layout")]
        [Authorization("Admin", "Vlasnik")]
        public async Task<IActionResult> SaveLayout([FromBody] TableLayoutRequest request)
        {
            await _service.SaveLayoutAsync(request);
            return Ok(new { Message = "Tables saved" });
        }
    }
}

