using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class City
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public int CountryId { get; set; }

    public virtual Country Country { get; set; } = null!;

    public virtual ICollection<Locale> Locales { get; set; } = new List<Locale>();
}
