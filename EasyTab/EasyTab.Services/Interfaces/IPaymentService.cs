using System.Threading.Tasks;
using EasyTab.Model;
using EasyTab.Model.SearchObject;
using EasyTab.Model.Models;
using EasyTab.Model.Responses;

namespace EasyTab.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<CreateOrderResponse> CreateOrderAsync(int reservationId);
        Task<PaymentResponse> CaptureOrderAsync(string orderId);
        Task<Notifications?> RefundCompletedPaymentAsync(int reservationId);
        Task<PagedResult<PaymentResponse>> GetByReservationIdAsync(int reservationId, BaseSearchObject search);
    }
}
