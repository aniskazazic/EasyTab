using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Requests
{
    public class ReservationUpdateRequest
    {
        public string? ReservationState { get; set; }
        public string? CancellationReason { get; set; }
    }
}
