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
    public class ConfirmedReservationState : BaseReservationState
    {
        public const string StateName = "Potvrđena";

        public ConfirmedReservationState(_220030Context context, IMapper mapper, IServiceProvider serviceProvider)
            : base(context, mapper, serviceProvider)
        {
        }

        public override async Task<Reservations> CompleteAsync(int id)
        {
            var entity = await GetReservationOrThrowAsync(id);

            if (!string.Equals(entity.ReservationState, StateName, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Rezervacija mora biti potvrđena da bi bila završena.");
            }

            entity.ReservationState = CompletedReservationState.StateName;
            entity.CancelledById = null;
            entity.CancelledAt = null;
            entity.CancellationReason = null;

            try
            {
                var table = await _context.Tables
                    .Include(t => t.Locale)
                    .FirstOrDefaultAsync(t => t.Id == entity.TableId);
                var localeName = table?.Locale?.Name ?? "Lokal";

                _context.Notifications.Add(new Notification
                {
                    UserId = entity.UserId,
                    Title = "Rezervacija završena",
                    Message = $"Vaša rezervacija za {localeName} je uspješno završena. Hvala vam na posjeti!",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                });
            }
            catch { }

            await _context.SaveChangesAsync();

            return _mapper.Map<Reservations>(entity);
        }

        public override async Task<Reservations> CancelAsync(int id, string reason, int cancelledById)
        {
            var entity = await GetReservationOrThrowAsync(id);

            if (!string.Equals(entity.ReservationState, StateName, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Rezervacija mora biti potvrđena da bi bila otkazana.");
            }

            entity.ReservationState = CancelledReservationState.StateName;
            entity.CancelledById = cancelledById;
            entity.CancelledAt = DateTime.UtcNow;
            entity.CancellationReason = reason;

            try
            {
                var user = await _context.Users.FindAsync(entity.UserId);
                var table = await _context.Tables
                    .Include(t => t.Locale)
                    .FirstOrDefaultAsync(t => t.Id == entity.TableId);

                var localeName = table?.Locale?.Name ?? "Lokal";

                _context.Notifications.Add(new Notification
                {
                    UserId = entity.UserId,
                    Title = "Rezervacija otkazana",
                    Message = $"Vaša rezervacija za {localeName} ({entity.ReservationDate:dd.MM.yyyy} u {entity.StartTime:HH:mm}) je otkazana. Razlog: {reason}",
                    IsRead = false,
                    CreatedAt = DateTime.UtcNow
                });

                await _context.SaveChangesAsync();

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
            }
            catch
            {
                await _context.SaveChangesAsync();
            }

            return _mapper.Map<Reservations>(entity);
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(CompleteAsync), nameof(CancelAsync) };
        }
    }
}
