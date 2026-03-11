using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Requests
{
    public class AdminUpdateLocaleRequest
    {
        public string? LocaleName { get; set; }
        public int CityId { get; set; }
        public string? Address { get; set; }
        public int CategoryId { get; set; }
    }
}
