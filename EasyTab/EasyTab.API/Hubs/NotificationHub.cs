using Microsoft.AspNetCore.SignalR;

namespace EasyTab.API.Hubs
{
    public class NotificationHub : Hub
    {
        /// <summary>
        /// Klijent se pridružuje grupi vezanoj za svog userId
        /// Flutter klijent mora pozvati: hubConnection.invoke("JoinUserGroup", userId.toString())
        /// </summary>
        public async Task JoinUserGroup(string userId)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user_{userId}");
        }

        /// <summary>
        /// Klijent napušta grupu (opciono, SignalR to radi automatski pri disconnect)
        /// </summary>
        public async Task LeaveUserGroup(string userId)
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user_{userId}");
        }
    }
}
