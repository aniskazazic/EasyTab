using EasyTab.Model.Requests;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize(Roles = "Admin")]
    public class AdminController : ControllerBase
    {
        private readonly IAdminService _service;

        public AdminController(IAdminService service)
        {
            _service = service;
        }

        [HttpGet("stats")]
        public async Task<IActionResult> GetStats()
        {
            return Ok(await _service.GetStats());
        }

        [HttpGet("analytics")]
        public async Task<IActionResult> GetAnalytics()
        {
            return Ok(await _service.GetAnalytics());
        }

        [HttpGet("locales")]
        public async Task<IActionResult> GetAllLocales(
            [FromQuery] string? search,
            [FromQuery] bool showDeleted = false,
            [FromQuery] int page = 0,
            [FromQuery] int pageSize = 10)
        {
            return Ok(await _service.GetAllLocales(search, showDeleted, page, pageSize));
        }

        [HttpPut("locales/{id}")]
        public async Task<IActionResult> UpdateLocale(int id, [FromBody] AdminUpdateLocaleRequest request)
        {
            await _service.UpdateLocale(id, request);
            return Ok(new { Message = "Lokal uspješno ažuriran." });
        }

        [HttpPut("locales/{id}/reactivate")]
        public async Task<IActionResult> ReactivateLocale(int id)
        {
            await _service.ReactivateLocale(id);
            return Ok(new { Message = "Lokal uspješno reaktiviran." });
        }
        
    }
}
