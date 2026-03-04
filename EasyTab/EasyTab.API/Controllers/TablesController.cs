using EasyTab.API.Controllers.BaseControllers;
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
    public class TablesController : BaseCRUDController<Tables, TableSearchObject, TableInsertRequest, TableUpdateRequest>
    {
        public ITableService _service;
        public TablesController(ITableService service) : base(service)
        {
            _service = service;
        }

        [HttpPost("save-layout")]
        public IActionResult SaveLayout([FromBody] TableLayoutRequest request)
        {
            _service.SaveLayout(request);
            return Ok(new { Message = "Tables saved" });
        }
    }
}

