using System;
using System.ComponentModel.DataAnnotations;

namespace EasyTab.Services.Database
{
    public partial class Payment
    {
        public int Id { get; set; }

        public int ReservationId { get; set; }

        public decimal AmountKm { get; set; }

        public decimal Amount { get; set; }

        [MaxLength(10)]
        public string Currency { get; set; } = null!;

        [MaxLength(1000)]
        public string? ApprovalUrl { get; set; }

        [MaxLength(100)]
        public string PayPalOrderId { get; set; } = null!;

        [MaxLength(100)]
        public string? PayPalCaptureId { get; set; }

        [MaxLength(100)]
        public string? PayPalRefundId { get; set; }

        [MaxLength(50)]
        public string Status { get; set; } = null!;

        public DateTime CreatedAt { get; set; }

        public DateTime? CompletedAt { get; set; }

        public decimal? RefundedAmount { get; set; }

        public DateTime? RefundedAt { get; set; }

        public virtual Reservation Reservation { get; set; } = null!;
    }
}
