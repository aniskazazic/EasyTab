using EasyTab.API.Controllers.BaseControllers;
using EasyTab.API.Filters;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.Interfaces;
using EasyTab.Services.Services;
using Microsoft.AspNetCore.Mvc;
using EasyTab.Model;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReservationsController : BaseCRUDController<Reservations, ReservationSearchObject, ReservationInsertRequest, ReservationUpdateRequest>
    {
        private readonly IReservationService _reservationService;
        public ReservationsController(IReservationService service) : base(service)
        {
            _reservationService = service;
        }

        [Authorization]
        public override Task<Reservations> Create([FromBody] ReservationInsertRequest request) => base.Create(request);

        [Authorization(RoleNames.Admin, RoleNames.Vlasnik, RoleNames.Radnik)]
        public override Task<Reservations?> Update(int id, [FromBody] ReservationUpdateRequest request) => base.Update(id, request);

        [Authorization(RoleNames.Admin, RoleNames.Vlasnik, RoleNames.Radnik)]
        public override Task<bool> Delete(int id) => base.Delete(id);

        [HttpGet("payment-summary")]
        [Authorization(RoleNames.Admin, RoleNames.Vlasnik)]
        public Task<PaymentSummary> GetPaymentSummary([FromQuery] PaymentSummarySearchObject search)
            => _reservationService.GetPaymentSummaryAsync(search);

        [HttpGet("available-slots")]
        public async Task<IActionResult> GetAvailableSlots([FromQuery] int tableId, [FromQuery] DateTime date)
        {
            var slots = await _reservationService.GetAvailableSlotsAsync(tableId, date);
            return Ok(slots);
        }

        [HttpPut("cancel/{id}")]
        public async Task<IActionResult> CancelReservation(int id, [FromBody] CancelReservationRequest request)
        {
            await _reservationService.CancelReservationAsync(id, request.Reason);
            return Ok(new { Message = "Rezervacija otkazana!" });
        }

        [HttpPut("confirm/{id}")]
        [Authorization(RoleNames.Admin, RoleNames.Vlasnik, RoleNames.Radnik)]
        public async Task<IActionResult> ConfirmReservation(int id)
        {
            var reservation = await _reservationService.ConfirmAsync(id);
            return Ok(reservation);
        }

        [HttpPut("complete/{id}")]
        [Authorization(RoleNames.Admin, RoleNames.Vlasnik, RoleNames.Radnik)]
        public async Task<IActionResult> CompleteReservation(int id)
        {
            var reservation = await _reservationService.CompleteAsync(id);
            return Ok(reservation);
        }

        [HttpGet("allowed-actions/{id}")]
        [Authorization(RoleNames.Admin, RoleNames.Vlasnik, RoleNames.Radnik)]
        public async Task<IActionResult> GetAllowedActions(int id)
        {
            var actions = await _reservationService.GetAllowedActionsAsync(id);
            return Ok(actions);
        }
    }
}
