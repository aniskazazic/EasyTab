using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Services.Database;
using MapsterMapper;
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
            _context.Reservations.Add(entity);
            await _context.SaveChangesAsync();
            return _mapper.Map<Reservations>(entity);
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { "Create" };
        }
    }
}
