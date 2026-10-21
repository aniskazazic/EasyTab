using System.Collections.Generic;
using System.Threading.Tasks;
using EasyTab.API.Filters;
using EasyTab.Model.Models;
using EasyTab.Model.Responses;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization]
    public class PaymentsController : ControllerBase
    {
        private readonly IPaymentService _paymentService;

        public PaymentsController(IPaymentService paymentService)
        {
            _paymentService = paymentService;
        }

        [HttpPost("create-order/{reservationId}")]
        public async Task<ActionResult<CreateOrderResponse>> CreateOrder(int reservationId)
        {
            var result = await _paymentService.CreateOrderAsync(reservationId);
            return Ok(result);
        }

        [HttpPost("capture/{orderId}")]
        public async Task<ActionResult<PaymentResponse>> Capture(string orderId)
        {
            var result = await _paymentService.CaptureOrderAsync(orderId);
            return Ok(result);
        }

        [HttpGet("by-reservation/{id}")]
        public async Task<ActionResult<List<PaymentResponse>>> GetByReservation(int id)
        {
            var result = await _paymentService.GetByReservationIdAsync(id);
            return Ok(result);
        }
    }
}
