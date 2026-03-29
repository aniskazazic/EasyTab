using EasyTab.Services.Interfaces;
using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class Worker : ISoftDelete
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public int LocaleId { get; set; }

    public DateTime HireDate { get; set; }

    public DateTime? EndDate { get; set; }

    public virtual Locale Locale { get; set; } = null!;

    public virtual User User { get; set; } = null!;

    public DateTime? DeletedAt { get; set; }

    public bool IsDeleted { get; set; }
}
