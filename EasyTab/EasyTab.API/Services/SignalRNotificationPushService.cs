using EasyTab.API.Hubs;
using EasyTab.Model.Models;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace EasyTab.API.Services
{
    public class SignalRNotificationPushService : INotificationPushService
    {
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<SignalRNotificationPushService> _logger;

        public SignalRNotificationPushService(
            IHubContext<NotificationHub> hubContext,
            ILogger<SignalRNotificationPushService> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task PushAsync(Notifications notification, CancellationToken cancellationToken = default)
        {
            try
            {
                await _hubContext.Clients
                    .User(notification.UserId.ToString())
                    .SendAsync("NotificationReceived", notification, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "SignalR notification push failed. NotificationId: {NotificationId}, UserId: {UserId}", notification.Id, notification.UserId);
            }
        }
    }
}
