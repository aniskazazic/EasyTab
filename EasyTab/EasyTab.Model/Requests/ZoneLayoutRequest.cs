using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Requests
{
    public class ZoneLayoutRequest
    {
        public int LocaleId { get; set; }
        public List<ZoneItemRequest> Zones { get; set; }
    }

    public class ZoneItemRequest
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public double XCoordinate { get; set; }
        public double YCoordinate { get; set; }
        public double Width { get; set; }
        public double Height { get; set; }
    }
}
