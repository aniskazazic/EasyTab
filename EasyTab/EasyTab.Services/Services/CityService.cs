using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class CityService : BaseCRUDService<Cities, CitySearchObject, City, CityInsertRequest, CityUpdateRequest>, ICityService
    {
        public CityService(_220030Context context, IMapper mapper) : base(context,mapper)
        {
        }

        public override IQueryable<City> AddFilter(IQueryable<City> query, CitySearchObject search)
        {
            if (!string.IsNullOrEmpty(search?.Name))
                query = query.Where(x => x.Name.Contains(search.Name));

            if (search?.CountryId.HasValue == true)
                query = query.Where(x => x.CountryId == search.CountryId);

            return base.AddFilter(query, search);
        }
    }
}
