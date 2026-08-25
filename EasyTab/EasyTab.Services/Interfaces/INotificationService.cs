using EasyTab.Model.Models;

namespace EasyTab.Services.Interfaces
{
    public interface INotificationService
    {
        Task<List<Notifications>> GetByUserIdAsync(int userId);
        Task MarkAsReadAsync(int notificationId);
        Task MarkAllAsReadAsync(int userId);
        Task<Notifications> CreateAsync(int userId, string title, string message);
    }
}
