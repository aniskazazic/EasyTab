using EasyTab.Model.Models;
using EasyTab.Services.Database;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace EasyTab.Services.ReservationStateMachine
{
    public class CancelledReservationState : BaseReservationState
    {
        public const string StateName = "Otkazana";

        public CancelledReservationState(_220030Context context, IMapper mapper, IServiceProvider serviceProvider)
            : base(context, mapper, serviceProvider)
        {
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string>();
        }
    }
}
