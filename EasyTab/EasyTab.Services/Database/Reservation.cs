using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace EasyTab.Services.Database;

public partial class Reservation
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public int TableId { get; set; }

    public DateTime ReservationDate { get; set; }

    public TimeOnly StartTime { get; set; }

    public TimeOnly EndTime { get; set; }

    public DateTime CreatedAt { get; set; }

    public int? ApprovedById { get; set; }

    public DateTime? ApprovedAt { get; set; }

    public int? CancelledById { get; set; }

    public DateTime? CancelledAt { get; set; }

    public string? CancellationReason { get; set; }

    public virtual Table Table { get; set; } = null!;

    public virtual User User { get; set; } = null!;

    public virtual User? ApprovedBy { get; set; }

    public virtual User? CancelledBy { get; set; }

    [MaxLength(1000)]
    public string ReservationState { get; set; } = string.Empty;
}
