using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.Requests
{
    public class UserInsertRequest
    {
        public string FirstName { get; set; } = null!;

        public string LastName { get; set; } = null!;

        public string Email { get; set; } = null!;

        public string Username { get; set; } = null!;

        public string? Password { get; set; }

        public string? PasswordConfirmation { get; set; }

        public string? PhoneNumber { get; set; }

        public DateTime? BirthDate { get; set; }
        public List<int>? RoleIds { get; set; }


    }
}
