using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Models
{
    public class Tables
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public int LocaleId { get; set; }
        public double XCoordinate { get; set; }
        public double YCoordinate { get; set; }
        public int NumberOfGuests { get; set; }
    }
}
