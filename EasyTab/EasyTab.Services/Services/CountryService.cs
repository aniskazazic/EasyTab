using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class CountryService : BaseCRUDService<Countries, CountrySearchObject, Country, CountryUpsertRequest, CountryUpsertRequest>, ICountryService
    {
        public CountryService(_220030Context context, IMapper mapper, IValidator<CountryUpsertRequest> insertValidator, IValidator<CountryUpsertRequest> updateValidator) : base(context,mapper, insertValidator, updateValidator) {  }

    }
}
