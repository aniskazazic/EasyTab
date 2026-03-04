using EasyTab.Services.Interfaces;
using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class Locale : ISoftDelete
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string Address { get; set; } = null!;

    public TimeOnly StartOfWorkingHours { get; set; }

    public TimeOnly EndOfWorkingHours { get; set; }

    public double LengthOfReservation { get; set; }

    public string? Logo { get; set; }

    public int CityId { get; set; }

    public int CategoryId { get; set; }

    public int OwnerId { get; set; }

    public bool IsDeleted { get; set; }

    public DateTime? DeletedAt { get; set; }

    public string? PhoneNumber { get; set; }

    public virtual Category Category { get; set; } = null!;

    public virtual City City { get; set; } = null!;

    public virtual ICollection<Favourite> Favourites { get; set; } = new List<Favourite>();

    public virtual ICollection<LocaleImage> LocaleImages { get; set; } = new List<LocaleImage>();

    public virtual User Owner { get; set; } = null!;

    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    public virtual ICollection<Table> Tables { get; set; } = new List<Table>();

    public virtual ICollection<Worker> Workers { get; set; } = new List<Worker>();

    public virtual ICollection<Zone> Zones { get; set; } = new List<Zone>();
}
