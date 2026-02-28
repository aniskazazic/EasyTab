using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class LocaleImage
{
    public int Id { get; set; }

    public string ImageUrl { get; set; } = null!;

    public int LocaleId { get; set; }

    public virtual Locale Locale { get; set; } = null!;
}
