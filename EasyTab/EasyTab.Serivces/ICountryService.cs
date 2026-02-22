using EasyTab.Model;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Serivces
{
    public interface ICountryService
    {
        List<Countries> GetCountries();
    }
}
