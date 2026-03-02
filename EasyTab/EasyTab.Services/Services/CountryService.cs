using EasyTab.Model;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using EasyTab.Model.SearchObject;
using EasyTab.Model.Requests;
using MapsterMapper;
using System.Threading.Tasks;
using EasyTab.Services.Interfaces;

namespace EasyTab.Services.Services
{
    public class CountryService : BaseCRUDService<Countries, CountrySearchObject, Country, CountryUpsertRequest, CountryUpsertRequest>, ICountryService
    {
        public CountryService(_220030Context context, IMapper mapper) : base(context,mapper) {  }

    }
}
