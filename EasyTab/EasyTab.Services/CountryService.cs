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

namespace EasyTab.Services
{
    public class CountryService : BaseCRUDService<Countries, CountrySearchObject, Country, CountryInsertRequest, CountryUpdateRequest>, ICountryService
    {
        public CountryService(_220030Context context, IMapper mapper) : base(context,mapper) {  }

    }
}
