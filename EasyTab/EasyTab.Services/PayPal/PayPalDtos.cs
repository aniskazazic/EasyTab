using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace EasyTab.Services.PayPal
{
    public class PayPalTokenResponse
    {
        [JsonPropertyName("access_token")]
        public string AccessToken { get; set; } = string.Empty;

        [JsonPropertyName("token_type")]
        public string TokenType { get; set; } = string.Empty;

        [JsonPropertyName("expires_in")]
        public int ExpiresIn { get; set; }
    }

    public class PayPalOrderResponse
    {
        [JsonPropertyName("id")]
        public string Id { get; set; } = string.Empty;

        [JsonPropertyName("status")]
        public string Status { get; set; } = string.Empty;

        [JsonPropertyName("links")]
        public List<PayPalLink>? Links { get; set; }

        [JsonPropertyName("purchase_units")]
        public List<PayPalPurchaseUnit>? PurchaseUnits { get; set; }
    }

    public class PayPalLink
    {
        [JsonPropertyName("href")]
        public string Href { get; set; } = string.Empty;

        [JsonPropertyName("rel")]
        public string Rel { get; set; } = string.Empty;

        [JsonPropertyName("method")]
        public string? Method { get; set; }
    }

    public class PayPalPurchaseUnit
    {
        [JsonPropertyName("reference_id")]
        public string? ReferenceId { get; set; }

        [JsonPropertyName("amount")]
        public PayPalAmount? Amount { get; set; }

        [JsonPropertyName("payments")]
        public PayPalPayments? Payments { get; set; }
    }

    public class PayPalPayments
    {
        [JsonPropertyName("captures")]
        public List<PayPalCapture>? Captures { get; set; }

        [JsonPropertyName("refunds")]
        public List<PayPalRefund>? Refunds { get; set; }
    }

    public class PayPalCapture
    {
        [JsonPropertyName("id")]
        public string Id { get; set; } = string.Empty;

        [JsonPropertyName("status")]
        public string Status { get; set; } = string.Empty;

        [JsonPropertyName("amount")]
        public PayPalAmount? Amount { get; set; }
    }

    public class PayPalRefund
    {
        [JsonPropertyName("id")]
        public string Id { get; set; } = string.Empty;

        [JsonPropertyName("status")]
        public string Status { get; set; } = string.Empty;

        [JsonPropertyName("amount")]
        public PayPalAmount? Amount { get; set; }
    }

    public class PayPalAmount
    {
        [JsonPropertyName("currency_code")]
        public string CurrencyCode { get; set; } = string.Empty;

        [JsonPropertyName("value")]
        public string Value { get; set; } = string.Empty;
    }

    public class PayPalCaptureResult
    {
        public string CaptureId { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public decimal Amount { get; set; }
        public string Currency { get; set; } = string.Empty;
    }

    public class PayPalRefundResult
    {
        public string? RefundId { get; set; }
        public string Status { get; set; } = string.Empty;
        public bool AlreadyRefunded { get; set; }
    }

    public class PayPalErrorResponse
    {
        [JsonPropertyName("name")]
        public string? Name { get; set; }

        [JsonPropertyName("message")]
        public string? Message { get; set; }

        [JsonPropertyName("debug_id")]
        public string? DebugId { get; set; }

        [JsonPropertyName("details")]
        public List<PayPalErrorDetail>? Details { get; set; }
    }

    public class PayPalErrorDetail
    {
        [JsonPropertyName("issue")]
        public string? Issue { get; set; }

        [JsonPropertyName("description")]
        public string? Description { get; set; }

        [JsonPropertyName("field")]
        public string? Field { get; set; }
    }
}
