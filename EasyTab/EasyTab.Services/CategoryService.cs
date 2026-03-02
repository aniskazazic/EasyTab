using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services
{
    public class CategoryService : BaseCRUDService<Categories, CategorySearchObject,Category, CategoryInsertRequest, CategoryUpdateRequest>, ICategoryService
    {
        public CategoryService(_220030Context context, IMapper mapper) : base(context, mapper) { }

        public override IQueryable<Category> AddFilter(IQueryable<Category> query, CategorySearchObject search)
        {
            if (!string.IsNullOrWhiteSpace(search?.Name))
            {
                query = query.Where(x => x.Name.StartsWith(search.Name));
            }
            return base.AddFilter(query, search);
        }
    }
}
