using EasyTab.Model;
using EasyTab.Model.SearchObject;
using System.Threading.Tasks;
using EasyTab.API.Filters;
using EasyTab.Model.Models;
using EasyTab.Model.Responses;
using EasyTab.Model.Requests;
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

        [HttpPost("checkout")]
        public async Task<ActionResult<CreateOrderResponse>> Checkout([FromBody] ReservationCheckoutRequest request)
            => Ok(await _paymentService.CreateCheckoutAsync(request));

        [HttpPost("checkout/{orderId}/capture")]
        public async Task<ActionResult<PaymentResponse>> CaptureCheckout(string orderId)
            => Ok(await _paymentService.CaptureCheckoutAsync(orderId));

        [HttpGet("by-reservation/{id}")]
        public async Task<ActionResult<PagedResult<PaymentResponse>>> GetByReservation(int id, [FromQuery] BaseSearchObject search)
        {
            var result = await _paymentService.GetByReservationIdAsync(id, search);
            return Ok(result);
        }
    }
}
