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
        public IActionResult CancelReservation(int id)
        {
            _service.CancelReservation(id);
            return Ok(new { Message = "Rezervacija otkazana!" });
        }
    }
}
