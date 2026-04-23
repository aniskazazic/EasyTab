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
    public class CategoryService : BaseCRUDService<Categories, CategorySearchObject,Category, CategoryUpsertRequest, CategoryUpsertRequest>, ICategoryService
    {
        private readonly ILogger<CategoryService> _logger;

        public CategoryService(_220030Context context, IMapper mapper, ILogger<CategoryService> logger, IValidator<CategoryUpsertRequest> insertValidator, IValidator<CategoryUpsertRequest> updateValidator) 
            : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
        }

        public override async Task<Categories> CreateAsync(CategoryUpsertRequest request)
        {
            _logger.LogInformation("Creating category. CategoryName: {CategoryName}", request.Name);
            return await base.CreateAsync(request);
        }

        public override async Task<Categories?> UpdateAsync(int id, CategoryUpsertRequest request)
        {
            _logger.LogInformation("Updating category. CategoryId: {CategoryId}, CategoryName: {CategoryName}", id, request.Name);
            return await base.UpdateAsync(id, request);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            _logger.LogWarning("Deleting category. CategoryId: {CategoryId}", id);
            return await base.DeleteAsync(id);
        }

        protected override IQueryable<Category> ApplyFilter(IQueryable<Category> query, CategorySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search?.Name))
            {
                query = query.Where(x => x.Name.StartsWith(search.Name));
            }
            return base.ApplyFilter(query, search);
        }
    }
}
