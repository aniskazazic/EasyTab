using System;

namespace EasyTab.Model.Requests
{
    public class UserRegisterRequest
    {
        public string FirstName { get; set; } = null!;
        public string LastName { get; set; } = null!;
        public string Email { get; set; } = null!;
        public string Username { get; set; } = null!;
        public string Password { get; set; } = null!;
        public string PasswordConfirmation { get; set; } = null!;
        public string? PhoneNumber { get; set; }
        public DateTime? BirthDate { get; set; }
        public string? ProfilePicture { get; set; }
    }
}