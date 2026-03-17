using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
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
        protected override IQueryable<City> ApplyFilter(IQueryable<City> query, CitySearchObject search)
        {
            query = query.Include(x => x.Country);

            if (!string.IsNullOrEmpty(search?.Name))
                query = query.Where(x => x.Name.Contains(search.Name));

            if (search?.CountryId.HasValue == true)
                query = query.Where(x => x.CountryId == search.CountryId);

            return base.ApplyFilter(query, search);
        }

    }
}
