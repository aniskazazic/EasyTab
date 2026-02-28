using System;
using System.Collections.Generic;

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

    public bool IsCancelled { get; set; }

    public virtual Table Table { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
