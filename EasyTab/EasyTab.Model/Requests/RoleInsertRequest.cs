using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Text;

namespace EasyTab.Model.Requests
{
    public class RoleInsertRequest
    {
        [Required(ErrorMessage = "Naziv uloge je obavezan.")]
        public string Name { get; set; } = null!;
        public string? Description { get; set; }
    }
}
