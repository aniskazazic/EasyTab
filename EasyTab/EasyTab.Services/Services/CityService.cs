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
    public class CityService : BaseCRUDService<Cities, CitySearchObject, City, CityInsertRequest, CityUpdateRequest>, ICityService
    {
        private readonly ILogger<CityService> _logger;
        private readonly IMemoryCache _cache;
        private readonly LookupCacheVersionService _cacheVersions;
        private const string CacheGroup = "cities";

        public CityService(_220030Context context, IMapper mapper, ILogger<CityService> logger, IValidator<CityInsertRequest> insertValidator, IValidator<CityUpdateRequest> updateValidator, IMemoryCache cache, LookupCacheVersionService cacheVersions)
            : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
            _cache = cache;
            _cacheVersions = cacheVersions;
        }

        public override async Task<PagedResult<Cities>> GetAsync(CitySearchObject search)
        {
            var key = $"{CacheGroup}:{_cacheVersions.GetVersion(CacheGroup)}:{System.Text.Json.JsonSerializer.Serialize(search)}";
            if (_cache.TryGetValue(key, out PagedResult<Cities>? cached) && cached != null)
                return cached;

            var result = await base.GetAsync(search);
            _cache.Set(key, result, TimeSpan.FromMinutes(7));
            return result;
        }

        public override async Task<Cities> CreateAsync(CityInsertRequest request)
        {
            _logger.LogInformation("Creating city. CityName: {CityName}", request.Name);
            var result = await base.CreateAsync(request);
            _cacheVersions.Invalidate(CacheGroup);
            return result;
        }

        public override async Task<Cities?> UpdateAsync(int id, CityUpdateRequest request)
        {
            _logger.LogInformation("Updating city. CityId: {CityId}, CityName: {CityName}", id, request.Name);
            var result = await base.UpdateAsync(id, request);
            _cacheVersions.Invalidate(CacheGroup);
            return result;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            _logger.LogWarning("Deleting city. CityId: {CityId}", id);
            var result = await base.DeleteAsync(id);
            _cacheVersions.Invalidate(CacheGroup);
            return result;
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
