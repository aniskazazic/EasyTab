using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class Reaction
{
    public int Id { get; set; }

    public int ReviewId { get; set; }

    public int UserId { get; set; }

    public bool IsLike { get; set; }

    public virtual Review Review { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
