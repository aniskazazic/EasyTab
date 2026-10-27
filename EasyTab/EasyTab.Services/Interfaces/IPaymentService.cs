using System.Threading.Tasks;
using EasyTab.Model;
using EasyTab.Model.SearchObject;
using EasyTab.Model.Models;
using EasyTab.Model.Responses;
using EasyTab.Model.Requests;

namespace EasyTab.Services.Interfaces
{
    public interface IPaymentService
    {
        Task<CreateOrderResponse> CreateCheckoutAsync(ReservationCheckoutRequest request);
        Task<PaymentResponse> CaptureCheckoutAsync(string orderId);
        Task ReconcileCheckoutsAsync(CancellationToken cancellationToken);
        Task<Notifications?> RefundCompletedPaymentAsync(int reservationId);
        Task<PagedResult<PaymentResponse>> GetByReservationIdAsync(int reservationId, BaseSearchObject search);
    }
}
