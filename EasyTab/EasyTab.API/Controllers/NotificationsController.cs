using EasyTab.Services.Interfaces;
using EasyTab.API.Filters;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization]
    public class NotificationsController : ControllerBase
    {
        private readonly INotificationService _notificationService;

        public NotificationsController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        /// <summary>
        /// Dohvata sve notifikacije za određenog korisnika
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetByUserId([FromQuery] int userId)
        {
            var notifications = await _notificationService.GetByUserIdAsync(userId);
            return Ok(notifications);
        }

        /// <summary>
        /// Označava jednu notifikaciju kao pročitanu
        /// </summary>
        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkAsRead(int id)
        {
            await _notificationService.MarkAsReadAsync(id);
            return Ok(new { Message = "Notifikacija označena kao pročitana." });
        }

        /// <summary>
        /// Označava sve notifikacije korisnika kao pročitane
        /// </summary>
        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllAsRead([FromQuery] int userId)
        {
            await _notificationService.MarkAllAsReadAsync(userId);
            return Ok(new { Message = "Sve notifikacije označene kao pročitane." });
        }
    }
}
