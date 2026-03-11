using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class OwnerController : ControllerBase
    {
        private readonly IOwnerService _ownerService;

        public OwnerController(IOwnerService ownerService)
        {
            _ownerService = ownerService;
        }

        private int GetCurrentUserId()
        {
            return int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
        }

        [Authorize(Roles = "Owner")]
        [HttpGet("today-reservations")]
        public async Task<IActionResult> GetTodaysReservations(int localeId)
        {
            return Ok(await _ownerService.GetTodaysReservations(localeId));
        }

        [Authorize(Roles = "Owner")]
        [HttpGet("today-guests")]
        public async Task<IActionResult> GetTodaysGuests(int localeId)
        {
            return Ok(await _ownerService.GetTodaysGuests(localeId));
        }

        [Authorize(Roles = "Owner")]
        [HttpGet("active-tables")]
        public async Task<IActionResult> GetActiveTables(int localeId)
        {
            return Ok(await _ownerService.GetActiveTables(localeId));
        }

        [Authorize(Roles = "Owner")]
        [HttpGet("total-tables")]
        public async Task<IActionResult> GetTotalTables(int localeId)
        {
            return Ok(await _ownerService.GetTotalTables(localeId));
        }

        [Authorize(Roles = "Owner")]
        [HttpGet("my-locale/{localeId}")]
        public async Task<IActionResult> GetMyLocale(int localeId)
        {
            return Ok(await _ownerService.GetMyLocale(localeId)); 
        }

        [Authorize(Roles = "Owner")]
        [HttpGet("table-distribution")]
        public async Task<IActionResult> GetTableDistribution(int localeId)
        {
            return Ok(await _ownerService.GetTableDistribution(localeId));
        }

        [Authorize(Roles = "Owner, Worker")]
        [HttpGet("reservations")]
        public async Task<IActionResult> GetAllReservations(
            [FromQuery] string? q,
            [FromQuery] DateTime? date,
            [FromQuery] int page = 0,
            [FromQuery] int pageSize = 10)
        {
            var userId = GetCurrentUserId();
            return Ok(await _ownerService.GetAllReservations(userId, q, date, page, pageSize));
        }

        [HttpGet("check-owner/{localeId}")]
        public async Task<IActionResult> CheckIfOwner(int localeId)
        {
            return Ok(await _ownerService.CheckIfOwner(localeId, GetCurrentUserId()));
        }

        [HttpGet("check-owner-or-worker/{localeId}")]
        public async Task<IActionResult> CheckIfOwnerOrWorker(int localeId)
        {
            return Ok(await _ownerService.CheckIfOwnerOrWorker(localeId, GetCurrentUserId()));
        }
    }
}
