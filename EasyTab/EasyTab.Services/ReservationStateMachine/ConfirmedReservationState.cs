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
            await _context.SaveChangesAsync();

            // Publish RabbitMQ poruka za otkazivanje potvrđene rezervacije
            _ = Task.Run(async () =>
            {
                try
                {
                    var user = await _context.Users.FindAsync(entity.UserId);
                    var table = await _context.Tables
                        .Include(t => t.Locale)
                        .FirstOrDefaultAsync(t => t.Id == entity.TableId);

                    if (user != null && table?.Locale != null)
                    {
                        var publisher = _serviceProvider.GetRequiredService<IRabbitMQPublisher>();
                        await publisher.PublishReservationCancelledAsync(new ReservationCancelledMessage
                        {
                            ReservationId = entity.Id,
                            UserId = user.Id,
                            UserEmail = user.Email,
                            UserFullName = $"{user.FirstName} {user.LastName}",
                            LocaleName = table.Locale.Name,
                            ReservationDate = entity.ReservationDate,
                            StartTime = entity.StartTime.ToString("HH:mm"),
                            CancellationReason = reason
                        });
                    }
                }
                catch { /* publish greška ne blokira API */ }
            });

            return _mapper.Map<Reservations>(entity);
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(CompleteAsync), nameof(CancelAsync) };
        }
    }
}
