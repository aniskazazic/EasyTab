using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class Zone
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public int LocaleId { get; set; }

    public double Xcoordinate { get; set; }

    public double Ycoordinate { get; set; }

    public double Width { get; set; }

    public double Height { get; set; }

    public virtual Locale Locale { get; set; } = null!;
}
