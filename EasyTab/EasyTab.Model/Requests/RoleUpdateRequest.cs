using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace EasyTab.Model.Requests
{
    public class RoleUpdateRequest
    {
        [Required(ErrorMessage = "Naziv uloge je obavezan.")]
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
        public bool IsDeleted { get; set; }
        public DateTime? DeletedAt { get; set; }
    }
}
