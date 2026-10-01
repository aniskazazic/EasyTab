using EasyTab.Model.Exceptions;
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
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.ReservationStateMachine
{
    public class PendingReservationState : BaseReservationState
    {
        public const string StateName = "Na čekanju";

        public PendingReservationState(_220030Context context, IMapper mapper, IServiceProvider serviceProvider)
            : base(context, mapper, serviceProvider)
        {
        }

        public override async Task<Reservations> ConfirmAsync(int id, int approvedById)
        {
            var entity = await GetReservationOrThrowAsync(id);

            if (!string.Equals(entity.ReservationState, StateName, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Rezervacija mora biti u stanju 'Na čekanju' da bi bila potvrđena.");
            }

            entity.ReservationState = ConfirmedReservationState.StateName;
            entity.ApprovedById = approvedById;
            entity.ApprovedAt = DateTime.UtcNow;
            entity.CancelledById = null;
            entity.CancelledAt = null;
            entity.CancellationReason = null;

            await using var transaction = await _context.Database.BeginTransactionAsync();
            var user = await _context.Users.FindAsync(entity.UserId);
            var table = await _context.Tables
                .Include(t => t.Locale)
                .FirstOrDefaultAsync(t => t.Id == entity.TableId);

            var localeName = table?.Locale?.Name ?? "Lokal";
            var notifications = new List<Notification>
            {
                new Notification
                {
                    UserId = entity.UserId,
                    Title = "Rezervacija potvrđena",
                    Message = $"Vaša rezervacija za {localeName} ({entity.ReservationDate:dd.MM.yyyy} u {entity.StartTime:HH:mm}) je uspješno potvrđena!",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                }
            };

            _context.Notifications.AddRange(notifications);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            await PushNotificationsAsync(notifications);

            if (user != null && table?.Locale != null)
            {
                var message = new ReservationConfirmedMessage
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
                        await publisher.PublishReservationConfirmedAsync(message);
                    }
                    catch { /* publish greška ne blokira API */ }
                });
            }

            return _mapper.Map<Reservations>(entity);
        }

        public override async Task<Reservations> CancelAsync(int id, string reason, int cancelledById)
        {
            var entity = await GetReservationOrThrowAsync(id);

            if (!string.Equals(entity.ReservationState, StateName, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Rezervacija mora biti u stanju 'Na čekanju' da bi bila otkazana.");
            }

            entity.ReservationState = CancelledReservationState.StateName;
            entity.CancelledById = cancelledById;
            entity.CancelledAt = DateTime.UtcNow;
            entity.CancellationReason = reason;

            await using var transaction = await _context.Database.BeginTransactionAsync();
            var user = await _context.Users.FindAsync(entity.UserId);
            var table = await _context.Tables
                .Include(t => t.Locale)
                .FirstOrDefaultAsync(t => t.Id == entity.TableId);

            var localeName = table?.Locale?.Name ?? "Lokal";
            var notifications = new List<Notification>
            {
                new Notification
                {
                    UserId = entity.UserId,
                    Title = "Rezervacija otkazana",
                    Message = $"Vaša rezervacija za {localeName} ({entity.ReservationDate:dd.MM.yyyy} u {entity.StartTime:HH:mm}) je otkazana. Razlog: {reason}",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                }
            };

            if (cancelledById == entity.UserId && table?.Locale != null)
            {
                var localeAccessService = _serviceProvider.GetRequiredService<ILocaleAccessService>();
                var managerIds = await localeAccessService.GetLocaleManagerUserIdsAsync(table.LocaleId);
                foreach (var managerId in managerIds)
                {
                    notifications.Add(new Notification
                    {
                        UserId = managerId,
                        Title = "Rezervacija otkazana",
                        Message = $"Rezervacija za {localeName} ({entity.ReservationDate:dd.MM.yyyy} u {entity.StartTime:HH:mm}) je otkazana od strane korisnika. Razlog: {reason}",
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    });
                }
            }

            _context.Notifications.AddRange(notifications);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            await PushNotificationsAsync(notifications);

            if (user != null && table?.Locale != null)
            {
                var message = new ReservationCancelledMessage
                {
                    ReservationId = entity.Id,
                    UserId = user.Id,
                    UserEmail = user.Email,
                    UserFullName = $"{user.FirstName} {user.LastName}",
                    LocaleName = table.Locale.Name,
                    ReservationDate = entity.ReservationDate,
                    StartTime = entity.StartTime.ToString("HH:mm"),
                    CancellationReason = reason
                };

                var publisher = _serviceProvider.GetRequiredService<IRabbitMQPublisher>();
                _ = Task.Run(async () =>
                {
                    try
                    {
                        await publisher.PublishReservationCancelledAsync(message);
                    }
                    catch { /* publish greška ne blokira API */ }
                });
            }

            return _mapper.Map<Reservations>(entity);
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(ConfirmAsync), nameof(CancelAsync) };
        }
    }
}
