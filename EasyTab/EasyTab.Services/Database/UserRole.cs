using EasyTab.Services.Interfaces;
using System;
using System.Collections.Generic;

namespace EasyTab.Services.Database;

public partial class UserRole : ISoftDelete
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public int RoleId { get; set; }

    public bool IsDeleted { get; set; }

    public DateTime? DeletedAt { get; set; }

    public virtual Role Role { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
