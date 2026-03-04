using EasyTab.Model.SearchObject;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.SearchObjects
{
    public class ReservationSearchObject : BaseSearchObject
    {
        public int? UserId { get; set; }
        public int? TableId { get; set; }
        public int? LocaleId { get; set; }
        public bool? IsCancelled { get; set; }
        public bool? IsUpcoming { get; set; } // true = aktivne, false = prošle
    }
}
