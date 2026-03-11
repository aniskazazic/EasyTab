using EasyTab.Model;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Interfaces;
using EasyTab.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.BaseServices.Implementation
{
    public abstract class BaseService<TModel, TSearch, TDbEntity> : IService<TModel, TSearch> where TSearch : BaseSearchObject where TDbEntity : class where TModel : class
    {
        public _220030Context Context { get; set; }
        public IMapper Mapper { get; set; }
        public BaseService(_220030Context context, IMapper mapper)
        {
            Context = context;
            Mapper = mapper;
        }

        public virtual async Task<PagedResult<TModel>> GetAsync(TSearch search)
        {
            var query = Context.Set<TDbEntity>().AsQueryable();
            query = ApplyFilter(query, search);

            int? totalCount = null;
            if (search.IncludeTotalCount)
            {
                totalCount = await query.CountAsync();
            }

            if (!search.RetrieveAll)
            {
                if (search.Page.HasValue)
                {
                    query = query.Skip(search.Page.Value * search.PageSize.Value);
                }
                if (search.PageSize.HasValue)
                {
                    query = query.Take(search.PageSize.Value);
                }
            }



            var list = await query.ToListAsync();
            return new PagedResult<TModel>
            {
                Items = list.Select(MapToResponse).ToList(),
                TotalCount = totalCount
            };
        }

        protected virtual IQueryable<TDbEntity> ApplyFilter(IQueryable<TDbEntity> query, TSearch search)
        {
            return query;
        }


        public virtual async Task<TModel?> GetByIdAsync(int id)
        {
            var entity = await Context.Set<TDbEntity>().FindAsync(id);
            if (entity == null)
                return null;

            return MapToResponse(entity);
        }

        protected virtual TModel MapToResponse(TDbEntity entity)
        {
            return Mapper.Map<TModel>(entity);
        }
    }
}