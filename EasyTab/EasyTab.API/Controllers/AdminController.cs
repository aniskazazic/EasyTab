using EasyTab.API.Filters;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;
using EasyTab.Model;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization(RoleNames.Admin)]
    public class AdminController : ControllerBase
    {
        private readonly IAdminService _service;

        public AdminController(IAdminService service)
        {
            _service = service;
        }

        [HttpGet("analytics")]
        public async Task<IActionResult> GetAnalytics()
        {
            return Ok(await _service.GetAnalytics());
        }

        [HttpPut("locales/{id}/reactivate")]
        public async Task<IActionResult> ReactivateLocale(int id)
        {
            await _service.ReactivateLocale(id);
            return Ok(new { Message = "Lokal uspješno reaktiviran." });
        }
        
    }
}
