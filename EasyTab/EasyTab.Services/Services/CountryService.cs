using EasyTab.Model;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Caching.Memory;
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
        private readonly IMemoryCache _cache;
        private readonly LookupCacheVersionService _cacheVersions;
        private const string CacheGroup = "countries";

        public CountryService(_220030Context context, IMapper mapper, ILogger<CountryService> logger, IValidator<CountryUpsertRequest> insertValidator, IValidator<CountryUpsertRequest> updateValidator, IMemoryCache cache, LookupCacheVersionService cacheVersions)
            : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
            _cache = cache;
            _cacheVersions = cacheVersions;
        }

        public override async Task<PagedResult<Countries>> GetAsync(CountrySearchObject search)
        {
            var key = $"{CacheGroup}:{_cacheVersions.GetVersion(CacheGroup)}:{System.Text.Json.JsonSerializer.Serialize(search)}";
            if (_cache.TryGetValue(key, out PagedResult<Countries>? cached) && cached != null)
                return cached;

            var result = await base.GetAsync(search);
            _cache.Set(key, result, TimeSpan.FromMinutes(7));
            return result;
        }

        public override async Task<Countries> CreateAsync(CountryUpsertRequest request)
        {
            _logger.LogInformation("Creating country. CountryName: {CountryName}", request.Name);
            var result = await base.CreateAsync(request);
            _cacheVersions.Invalidate(CacheGroup);
            _cacheVersions.Invalidate("cities");
            return result;
        }

        public override async Task<Countries?> UpdateAsync(int id, CountryUpsertRequest request)
        {
            _logger.LogInformation("Updating country. CountryId: {CountryId}, CountryName: {CountryName}", id, request.Name);
            var result = await base.UpdateAsync(id, request);
            _cacheVersions.Invalidate(CacheGroup);
            _cacheVersions.Invalidate("cities");
            return result;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            _logger.LogWarning("Deleting country. CountryId: {CountryId}", id);
            var result = await base.DeleteAsync(id);
            _cacheVersions.Invalidate(CacheGroup);
            _cacheVersions.Invalidate("cities");
            return result;
        }

        protected override IQueryable<Country> ApplyFilter(IQueryable<Country> query, CountrySearchObject? search)
        {
            if (!string.IsNullOrEmpty(search?.Name))
            {
                query = query.Where(x => x.Name.Contains(search.Name));
            }

            return base.ApplyFilter(query, search);
        }
    }
}
