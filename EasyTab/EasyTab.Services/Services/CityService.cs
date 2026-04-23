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

        public CityService(_220030Context context, IMapper mapper, ILogger<CityService> logger, IValidator<CityInsertRequest> insertValidator, IValidator<CityUpdateRequest> updateValidator) 
            : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
        }

        public override async Task<Cities> CreateAsync(CityInsertRequest request)
        {
            _logger.LogInformation("Creating city. CityName: {CityName}", request.Name);
            return await base.CreateAsync(request);
        }

        public override async Task<Cities?> UpdateAsync(int id, CityUpdateRequest request)
        {
            _logger.LogInformation("Updating city. CityId: {CityId}, CityName: {CityName}", id, request.Name);
            return await base.UpdateAsync(id, request);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            _logger.LogWarning("Deleting city. CityId: {CityId}", id);
            return await base.DeleteAsync(id);
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
