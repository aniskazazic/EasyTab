using EasyTab.Model.Exceptions;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Services.Database;
using MapsterMapper;
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

        public override async Task<Reservations> ConfirmAsync(int id)
        {
            var entity = await GetReservationOrThrowAsync(id);

            if (!string.Equals(entity.ReservationState, StateName, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Rezervacija mora biti u stanju 'Na čekanju' da bi bila potvrđena.");
            }

            entity.ReservationState = ConfirmedReservationState.StateName;
            entity.IsCancelled = false;
            await _context.SaveChangesAsync();

            return _mapper.Map<Reservations>(entity);
        }

        public override async Task<Reservations> CancelAsync(int id)
        {
            var entity = await GetReservationOrThrowAsync(id);

            if (!string.Equals(entity.ReservationState, StateName, StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException("Rezervacija mora biti u stanju 'Na čekanju' da bi bila otkazana.");
            }

            entity.ReservationState = CancelledReservationState.StateName;
            entity.IsCancelled = true;
            await _context.SaveChangesAsync();

            return _mapper.Map<Reservations>(entity);
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { nameof(ConfirmAsync), nameof(CancelAsync) };
        }
    }
}
