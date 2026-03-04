using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.Models
{
    public class Roles
    {
        public int Id { get; set; }

        public string Name { get; set; } = null!;

        public string? Description { get; set; }

        public bool IsDeleted { get; set; }

        public DateTime? DeletedAt { get; set; }

    }
}
