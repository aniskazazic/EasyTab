namespace EasyTab.Model.Messages
{
    public class PasswordResetMessage
    {
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
    }
}
