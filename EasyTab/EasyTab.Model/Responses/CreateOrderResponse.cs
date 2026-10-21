namespace EasyTab.Model.Responses
{
    public class CreateOrderResponse
    {
        public string OrderId { get; set; } = string.Empty;
        public string? ApprovalUrl { get; set; }
    }
}
