using EasyTab.Model.Models;

namespace EasyTab.Services.Interfaces
{
    public interface INotificationPushService
    {
        Task PushAsync(Notifications notification, CancellationToken cancellationToken = default);
    }
}
