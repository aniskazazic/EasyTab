using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Models
{
    public class ReviewAverage
    {
        public float AverageRating { get; set; }
    }

    public class ReviewRatingCount
    {
        public int Excellent { get; set; }
        public int Good { get; set; }
        public int Average { get; set; }
        public int Poor { get; set; }
        public int Terrible { get; set; }
    }
}
