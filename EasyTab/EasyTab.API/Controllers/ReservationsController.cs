using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.Interfaces;
using EasyTab.Services.Services;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReservationsController : BaseCRUDController<Reservations, ReservationSearchObject, ReservationInsertRequest, ReservationUpdateRequest>
    {
        public IReservationService _service;
        public ReservationsController(IReservationService service) : base(service)
        {
            _service = service;
        }

        [HttpGet("available-slots")]
        public IActionResult GetAvailableSlots([FromQuery] int tableId, [FromQuery] DateTime date)
        {
            var slots = _service.GetAvailableSlots(tableId, date);
            return Ok(slots);
        }

        [HttpPut("cancel/{id}")]
        public async Task<IActionResult> CancelReservation(int id)
        {
            await _service.CancelReservationAsync(id);
            return Ok(new { Message = "Rezervacija otkazana!" });
        }

        [HttpPut("confirm/{id}")]
        public async Task<IActionResult> ConfirmReservation(int id)
        {
            var reservation = await _service.ConfirmAsync(id);
            return Ok(reservation);
        }

        [HttpPut("complete/{id}")]
        public async Task<IActionResult> CompleteReservation(int id)
        {
            var reservation = await _service.CompleteAsync(id);
            return Ok(reservation);
        }

        [HttpGet("allowed-actions/{id}")]
        public async Task<IActionResult> GetAllowedActions(int id)
        {
            var actions = await _service.GetAllowedActionsAsync(id);
            return Ok(actions);
        }
    }
}
