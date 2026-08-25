namespace EasyTab.Model.Messages
{
    public class UserRegisteredMessage
    {
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Username { get; set; } = string.Empty;
    }
}
