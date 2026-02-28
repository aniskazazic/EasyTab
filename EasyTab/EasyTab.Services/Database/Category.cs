using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class Category
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public virtual ICollection<Locale> Locales { get; set; } = new List<Locale>();
}
