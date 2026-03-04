using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Requests
{
    public class TableLayoutRequest
    {
        public int LocaleId { get; set; }
        public List<TableItemRequest> Tables { get; set; }
    }

    public class TableItemRequest
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public double XCoordinate { get; set; }
        public double YCoordinate { get; set; }
        public int NumberOfGuests { get; set; }
    }
}
