using EasyTab.Services.Interfaces;
using EasyTab.API.Filters;
using Microsoft.AspNetCore.Mvc;
using EasyTab.Model;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization]
    public class OwnerController : ControllerBase
    {
        private readonly IOwnerService _ownerService;
        private readonly ICurrentUserService _currentUser;

        public OwnerController(IOwnerService ownerService, ICurrentUserService currentUser)
        {
            _ownerService = ownerService;
            _currentUser = currentUser;
        }

        [Authorization(RoleNames.Vlasnik)]
        [HttpGet("today-reservations")]
        public async Task<IActionResult> GetTodaysReservations(int localeId)
        {
            return Ok(await _ownerService.GetTodaysReservations(localeId));
        }

        [Authorization(RoleNames.Vlasnik)]
        [HttpGet("today-guests")]
        public async Task<IActionResult> GetTodaysGuests(int localeId)
        {
            return Ok(await _ownerService.GetTodaysGuests(localeId));
        }

        [Authorization(RoleNames.Vlasnik)]
        [HttpGet("today-reserved-tables")]
        public async Task<IActionResult> GetTodaysReservedTables(int localeId)
        {
            return Ok(await _ownerService.GetTodaysReservedTables(localeId));
        }

        [Authorization(RoleNames.Vlasnik)]
        [HttpGet("total-tables")]
        public async Task<IActionResult> GetTotalTables(int localeId)
        {
            return Ok(await _ownerService.GetTotalTables(localeId));
        }

        [Authorization(RoleNames.Vlasnik)]
        [HttpGet("table-distribution")]
        public async Task<IActionResult> GetTableDistribution(int localeId)
        {
            return Ok(await _ownerService.GetTableDistribution(localeId));
        }

        [Authorization(RoleNames.Vlasnik, RoleNames.Radnik)]
        [HttpGet("reservations")]
        public async Task<IActionResult> GetAllReservations(
            [FromQuery] string? q,
            [FromQuery] DateTime? date,
            [FromQuery] string? reservationState,
            [FromQuery] int page = 0,
            [FromQuery] int pageSize = 10)
        {
            var userId = _currentUser.UserId;
            return Ok(await _ownerService.GetAllReservations(userId, q, date, reservationState, page, pageSize));
        }

        [HttpGet("check-owner-or-worker/{localeId}")]
        [Authorization]
        public async Task<IActionResult> CheckIfOwnerOrWorker(int localeId)
        {
            return Ok(await _ownerService.CheckIfOwnerOrWorker(localeId, _currentUser.UserId));
        }
    }
}
