using EasyTab.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Serivces
{
    public class CountryService : ICountryService
    {
        public List<Countries> Countries = new List<Countries>
        {
            new Countries { CountryId = 1, Name = "United States" },
            new Countries { CountryId = 2, Name = "Canada" },
            new Countries { CountryId = 3, Name = "Mexico" },
        };

        public List<Countries> GetCountries()
        {
            return Countries;
        }
    }
}
