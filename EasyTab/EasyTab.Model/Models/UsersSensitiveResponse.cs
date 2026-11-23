namespace EasyTab.Model.Models
{
    public partial class UsersSensitiveResponse : Users
    {
        public string PasswordHash { get; set; } = string.Empty;
        public string PasswordSalt { get; set; } = string.Empty;

    }
}
