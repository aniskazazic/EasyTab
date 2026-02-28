using EasyTab.Model;
using EasyTab.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services
{
    public class CountryService : ICountryService
    {
        public _220030Context Context { get; set; }
        public CountryService(_220030Context context) { 
            Context = context;
        }

        public virtual List<Model.Countries> GetCountries()
        {
            var list = Context.Countries.ToList();
            var result = new List<Model.Countries>();
            list.ForEach(item =>
            {
                result.Add(new Model.Countries()
                {
                    CountryId = item.Id,
                    Name = item.Name
                });
            });

            return result;
        }
    }
}
