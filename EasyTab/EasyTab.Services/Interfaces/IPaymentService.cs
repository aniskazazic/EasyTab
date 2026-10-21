using System.Collections.Generic;
using System.Threading.Tasks;
using EasyTab.Model.Models;
using EasyTab.Model.Responses;

namespace EasyTab.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<CreateOrderResponse> CreateOrderAsync(int reservationId);
        Task<PaymentResponse> CaptureOrderAsync(string orderId);
        Task<List<PaymentResponse>> GetByReservationIdAsync(int reservationId);
    }
}
