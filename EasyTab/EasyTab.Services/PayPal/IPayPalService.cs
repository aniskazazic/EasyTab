using System.Threading.Tasks;

namespace EasyTab.Services.PayPal
{
    public interface IPayPalService
    {
        Task<(string orderId, string? approvalUrl)> CreateOrderAsync(decimal amountEur, string currency, string referenceId, string description, string? requestId = null);
        Task<PayPalOrderResponse> GetOrderAsync(string orderId);
        Task<PayPalCaptureResult> CaptureOrderAsync(string orderId, string requestId);
        Task<PayPalRefundResult> RefundCaptureAsync(string captureId, decimal amountEur, string currency, string requestId);
    }
}
