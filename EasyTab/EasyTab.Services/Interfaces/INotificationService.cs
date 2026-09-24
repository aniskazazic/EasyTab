using EasyTab.Model.Models;

namespace EasyTab.Services.Interfaces
{
    public interface INotificationService
    {
        Task<List<Notifications>> GetByUserIdAsync();
        Task MarkAsReadAsync(int notificationId);
        Task MarkAllAsReadAsync();
        Task<Notifications> CreateAsync(int userId, string title, string message);
    }
}
