using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.Requests
{
    public class UserUpdateRequest
    {
        public string? FirstName { get; set; } = null!;

        public string? LastName { get; set; } = null!;

        public string? Username { get; set; }
        public string? Password { get; set; }

        public string? PasswordConfirmation { get; set; }

        public string? PhoneNumber { get; set; }
        public string? Email { get; set; }
        public DateTime? BirthDate { get; set; }
        public string? ProfilePicture { get; set; }
        public bool? IsDeleted { get; set; }

    }
}
