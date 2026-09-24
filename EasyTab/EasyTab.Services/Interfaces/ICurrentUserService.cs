namespace EasyTab.Services.Interfaces
{
    public interface ICurrentUserService
    {
        int UserId { get; }
        string? Role { get; }
        bool IsAdmin { get; }
    }
}
