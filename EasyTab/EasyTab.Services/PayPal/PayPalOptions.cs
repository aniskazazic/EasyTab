namespace EasyTab.Services.PayPal
{
    public class PayPalOptions
    {
        public const string SectionName = "PayPal";

        public string ClientId { get; set; } = string.Empty;
        public string Secret { get; set; } = string.Empty;
        public string BaseUrl { get; set; } = "https://api-m.sandbox.paypal.com";
        public string ReturnUrl { get; set; } = "easytab://payment-success";
        public string CancelUrl { get; set; } = "easytab://payment-cancel";
        public string Currency { get; set; } = "EUR";
        public decimal BamToEurRate { get; set; } = 1.95583m;
    }
}
