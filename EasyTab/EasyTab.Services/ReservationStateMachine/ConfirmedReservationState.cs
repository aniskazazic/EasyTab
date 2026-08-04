using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Services.Database;
using MapsterMapper;
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

            return _mapper.Map<Reservations>(entity);
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(CompleteAsync), nameof(CancelAsync) };
        }
    }
}
