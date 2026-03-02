using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.Requests
{
    public class RoleUpdateRequest
    {
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }
    }
}
