using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class Favourite
{
    public int Id { get; set; }

    public int LocaleId { get; set; }

    public int UserId { get; set; }

    public DateTime DateAdded { get; set; }

    public bool IsActive { get; set; }

    public virtual Locale Locale { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
