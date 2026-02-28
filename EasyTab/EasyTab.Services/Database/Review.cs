using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class Review
{
    public int Id { get; set; }

    public string Description { get; set; } = null!;

    public int Rating { get; set; }

    public int UserId { get; set; }

    public int LocaleId { get; set; }

    public DateTime DateAdded { get; set; }

    public bool IsDeleted { get; set; }

    public DateTime? DeletedAt { get; set; }

    public virtual Locale Locale { get; set; } = null!;

    public virtual ICollection<Reaction> Reactions { get; set; } = new List<Reaction>();

    public virtual User User { get; set; } = null!;
}
