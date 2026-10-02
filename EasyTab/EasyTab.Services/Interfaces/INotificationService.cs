using EasyTab.Model.Models;
using EasyTab.Model;
using EasyTab.Model.SearchObjects;

namespace EasyTab.Services.Interfaces
{
    public interface INotificationService
    {
        Task<List<Notifications>> GetByUserIdAsync();
        Task<PagedResult<Notifications>> GetAllAsync(NotificationSearchObject search);
        Task MarkAsReadAsync(int notificationId);
        Task MarkAllAsReadAsync();
        Task<Notifications> CreateAsync(int userId, string title, string message);
    }
}
