using EasyTab.Model.Models;
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
    public class CategoryService : BaseCRUDService<Categories, CategorySearchObject,Category, CategoryUpsertRequest, CategoryUpsertRequest>, ICategoryService
    {
        public CategoryService(_220030Context context, IMapper mapper) : base(context, mapper) { }

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
