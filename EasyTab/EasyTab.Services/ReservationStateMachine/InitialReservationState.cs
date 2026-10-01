using EasyTab.Model.Messages;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace EasyTab.Services.ReservationStateMachine
{
    public class InitialReservationState : BaseReservationState
    {
        public InitialReservationState(_220030Context context, IMapper mapper, IServiceProvider serviceProvider)
            : base(context, mapper, serviceProvider)
        {
        }

        public override async Task<Reservations> CreateAsync(ReservationInsertRequest request)
        {
            var entity = _mapper.Map<Reservation>(request);
            entity.ReservationState = PendingReservationState.StateName;

            await using var transaction = await _context.Database.BeginTransactionAsync();
            _context.Reservations.Add(entity);
            await _context.SaveChangesAsync();

            var user = await _context.Users.FindAsync(request.UserId);
            var table = await _context.Tables
                .Include(t => t.Locale)
                .FirstOrDefaultAsync(t => t.Id == request.TableId);

            var notifications = new List<Notification>();
            if (user != null && table?.Locale != null)
            {
                notifications.Add(new Notification
                {
                    UserId = user.Id,
                    Title = "Rezervacija na čekanju",
                    Message = $"Vaša rezervacija za {table.Locale.Name} ({entity.ReservationDate:dd.MM.yyyy} u {entity.StartTime:HH:mm}) je kreirana i čeka potvrdu lokala.",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                });

                var localeAccessService = _serviceProvider.GetRequiredService<ILocaleAccessService>();
                var managerIds = await localeAccessService.GetLocaleManagerUserIdsAsync(table.LocaleId);
                foreach (var managerId in managerIds.Where(id => id != user.Id))
                {
                    notifications.Add(new Notification
                    {
                        UserId = managerId,
                        Title = "Nova rezervacija",
                        Message = $"Nova rezervacija za {table.Locale.Name} ({entity.ReservationDate:dd.MM.yyyy} u {entity.StartTime:HH:mm}) čeka potvrdu.",
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    });
                }
            }

            _context.Notifications.AddRange(notifications);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            await PushNotificationsAsync(notifications);

            // Pripremi podatke za RabbitMQ poruku dok je DbContext još aktivan
            if (user != null && table?.Locale != null)
            {
                var message = new ReservationCreatedMessage
                {
                    ReservationId = entity.Id,
                    UserId = user.Id,
                    UserEmail = user.Email,
                    UserFullName = $"{user.FirstName} {user.LastName}",
                    LocaleName = table.Locale.Name,
                    ReservationDate = entity.ReservationDate,
                    StartTime = entity.StartTime.ToString("HH:mm"),
                    EndTime = entity.EndTime.ToString("HH:mm"),
                    NumberOfGuests = table.NumberOfGuests
                };

                var publisher = _serviceProvider.GetRequiredService<IRabbitMQPublisher>();
                _ = Task.Run(async () =>
                {
                    try
                    {
                        await publisher.PublishReservationCreatedAsync(message);
                    }
                    catch { /* publish greška ne blokira API */ }
                });
            }

            return _mapper.Map<Reservations>(entity);
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { "Create" };
        }
    }
}
