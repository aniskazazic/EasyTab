using Microsoft.AspNetCore.SignalR;

namespace EasyTab.API.Hubs
{
    public class UserIdProvider : IUserIdProvider
    {
        public string? GetUserId(HubConnectionContext connection)
        {
            return connection.User?.FindFirst("Id")?.Value;
        }
    }
}
