using System;
using System.Text.Json.Serialization;
using EasyTab.Model.Serialization;

namespace EasyTab.Model.Models
{
    public class PaymentResponse
    {
        public int Id { get; set; }
        public int ReservationId { get; set; }
        public decimal AmountKm { get; set; }
        public decimal Amount { get; set; }
        public string Currency { get; set; } = string.Empty;
        public string? ApprovalUrl { get; set; }
        public string PayPalOrderId { get; set; } = string.Empty;
        public string? PayPalCaptureId { get; set; }
        public string? PayPalRefundId { get; set; }
        public string Status { get; set; } = string.Empty;

        [JsonConverter(typeof(UtcDateTimeJsonConverter))]
        public DateTime CreatedAt { get; set; }

        [JsonConverter(typeof(UtcNullableDateTimeJsonConverter))]
        public DateTime? CompletedAt { get; set; }

        public decimal? RefundedAmount { get; set; }

        [JsonConverter(typeof(UtcNullableDateTimeJsonConverter))]
        public DateTime? RefundedAt { get; set; }
    }
}
