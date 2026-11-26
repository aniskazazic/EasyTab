namespace EasyTab.Services.PayPal
{
    public class PayPalOptions
    {
        public const string SectionName = "PayPal";

        public string ClientId { get; set; } = string.Empty;
        public string Secret { get; set; } = string.Empty;
        public string BaseUrl { get; set; } = string.Empty;
        public string ReturnUrl { get; set; } = string.Empty;
        public string CancelUrl { get; set; } = string.Empty;
        public string Currency { get; set; } = string.Empty;
        public decimal BamToEurRate { get; set; }
        public int CheckoutHoldMinutes { get; set; }

        // Jedino pravilo obračuna iznosa za PayPal: koriste ga i naplata (PaymentService) i seed.
        public decimal ToPayPalAmount(decimal amountKm) => Math.Round(amountKm / BamToEurRate, 2);
    }
}
