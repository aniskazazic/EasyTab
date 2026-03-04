using System;
using System.Collections.Generic;
using System.Data;
using System.Text;

namespace EasyTab.Model.Models
{
    public class UserRoles
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public int RoleId { get; set; }

        public bool IsDeleted { get; set; }

        public DateTime? DeletedAt { get; set; }

        public virtual Roles Role { get; set; } = null!;

    }
}
