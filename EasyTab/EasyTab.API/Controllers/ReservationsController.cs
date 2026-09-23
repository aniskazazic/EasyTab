using EasyTab.API.Controllers.BaseControllers;
using EasyTab.API.Filters;
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

        [Authorization]
        public override Task<Reservations> Create([FromBody] ReservationInsertRequest request) => base.Create(request);

        [Authorization("Admin", "Vlasnik", "Radnik")]
        public override Task<Reservations?> Update(int id, [FromBody] ReservationUpdateRequest request) => base.Update(id, request);

        [Authorization("Admin", "Vlasnik", "Radnik")]
        public override Task<bool> Delete(int id) => base.Delete(id);

        [HttpGet("available-slots")]
        public IActionResult GetAvailableSlots([FromQuery] int tableId, [FromQuery] DateTime date)
        {
            var slots = _service.GetAvailableSlots(tableId, date);
            return Ok(slots);
        }

        [HttpPut("cancel/{id}")]
        public async Task<IActionResult> CancelReservation(int id, [FromBody] CancelReservationRequest request)
        {
            await _service.CancelReservationAsync(id, request.Reason, request.CancelledById);
            return Ok(new { Message = "Rezervacija otkazana!" });
        }

        [HttpPut("confirm/{id}")]
        [Authorization("Admin", "Vlasnik", "Radnik")]
        public async Task<IActionResult> ConfirmReservation(int id, [FromQuery] int approvedById)
        {
            var reservation = await _service.ConfirmAsync(id, approvedById);
            return Ok(reservation);
        }

        [HttpPut("complete/{id}")]
        [Authorization("Admin", "Vlasnik", "Radnik")]
        public async Task<IActionResult> CompleteReservation(int id)
        {
            var reservation = await _service.CompleteAsync(id);
            return Ok(reservation);
        }

        [HttpGet("allowed-actions/{id}")]
        [Authorization("Admin", "Vlasnik", "Radnik")]
        public async Task<IActionResult> GetAllowedActions(int id)
        {
            var actions = await _service.GetAllowedActionsAsync(id);
            return Ok(actions);
        }
    }
}
