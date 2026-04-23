using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class CountryService : BaseCRUDService<Countries, CountrySearchObject, Country, CountryUpsertRequest, CountryUpsertRequest>, ICountryService
    {
        private readonly ILogger<CountryService> _logger;

        public CountryService(_220030Context context, IMapper mapper, ILogger<CountryService> logger, IValidator<CountryUpsertRequest> insertValidator, IValidator<CountryUpsertRequest> updateValidator) 
            : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
        }

        public override async Task<Countries> CreateAsync(CountryUpsertRequest request)
        {
            _logger.LogInformation("Creating country. CountryName: {CountryName}", request.Name);
            return await base.CreateAsync(request);
        }

        public override async Task<Countries?> UpdateAsync(int id, CountryUpsertRequest request)
        {
            _logger.LogInformation("Updating country. CountryId: {CountryId}, CountryName: {CountryName}", id, request.Name);
            return await base.UpdateAsync(id, request);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            _logger.LogWarning("Deleting country. CountryId: {CountryId}", id);
            return await base.DeleteAsync(id);
        }
    }
}
