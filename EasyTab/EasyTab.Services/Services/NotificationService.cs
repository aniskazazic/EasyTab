using EasyTab.Model.Models;
using EasyTab.Model;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;

namespace EasyTab.Services.Services
{
    public class NotificationService : INotificationService
    {
        private readonly _220030Context _context;
        private readonly IMapper _mapper;
        private readonly ICurrentUserService _currentUser;

        public NotificationService(_220030Context context, IMapper mapper, ICurrentUserService currentUser)
        {
            _context = context;
            _mapper = mapper;
            _currentUser = currentUser;
        }

        public async Task<List<Notifications>> GetByUserIdAsync()
        {
            var userId = _currentUser.UserId;
            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.CreatedAt)
                .ToListAsync();

            return _mapper.Map<List<Notifications>>(notifications);
        }

        public async Task<PagedResult<Notifications>> GetAllAsync(NotificationSearchObject search)
        {
            const int defaultPageSize = 10;
            const int maxPageSize = 100;
            var page = Math.Max(search.Page ?? 1, 1);
            var pageSize = Math.Clamp(search.PageSize ?? defaultPageSize, 1, maxPageSize);

            var query = _context.Notifications.AsNoTracking();
            var totalCount = search.IncludeTotalCount ?? true
                ? await query.CountAsync()
                : (int?)null;

            query = search.SortBy?.ToLowerInvariant() switch
            {
                "id" => query.OrderByDescending(n => n.Id),
                "userid" => query.OrderByDescending(n => n.UserId),
                "title" => query.OrderBy(n => n.Title).ThenByDescending(n => n.CreatedAt),
                "isread" => query.OrderBy(n => n.IsRead).ThenByDescending(n => n.CreatedAt),
                "createdat" or null or "" => query.OrderByDescending(n => n.CreatedAt).ThenByDescending(n => n.Id),
                _ => query.OrderByDescending(n => n.CreatedAt).ThenByDescending(n => n.Id)
            };

            var notifications = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<Notifications>
            {
                Items = _mapper.Map<List<Notifications>>(notifications),
                TotalCount = totalCount
            };
        }

        public async Task MarkAsReadAsync(int notificationId)
        {
            var notification = await _context.Notifications
                .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == _currentUser.UserId);
            if (notification != null)
            {
                notification.IsRead = true;
                await _context.SaveChangesAsync();
            }
        }

        public async Task MarkAllAsReadAsync()
        {
            var userId = _currentUser.UserId;
            var notifications = await _context.Notifications
                .Where(n => n.UserId == userId && !n.IsRead)
                .ToListAsync();

            foreach (var n in notifications)
                n.IsRead = true;

            await _context.SaveChangesAsync();
        }

        public async Task<Notifications> CreateAsync(int userId, string title, string message)
        {
            var notification = new Notification
            {
                UserId = userId,
                Title = title,
                Message = message,
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            return _mapper.Map<Notifications>(notification);
        }
    }
}
