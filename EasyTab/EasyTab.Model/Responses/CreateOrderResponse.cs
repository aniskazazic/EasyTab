namespace EasyTab.Model.Responses
{
    public class CreateOrderResponse
    {
        public string OrderId { get; set; } = string.Empty;
        public string? ApprovalUrl { get; set; }
        public decimal AmountKm { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = string.Empty;
        public decimal ExchangeRate { get; set; }
    }
}
