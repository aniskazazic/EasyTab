using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class Table
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public int LocaleId { get; set; }

    public double Xcoordinate { get; set; }

    public double Ycoordinate { get; set; }

    public int NumberOfGuests { get; set; }

    public virtual Locale Locale { get; set; } = null!;

    public virtual ICollection<Reservation> Reservations { get; set; } = new List<Reservation>();
}
