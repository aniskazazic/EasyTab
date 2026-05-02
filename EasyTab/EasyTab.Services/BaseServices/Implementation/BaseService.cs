using Azure;
using EasyTab.Model;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Interfaces;
using EasyTab.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Linq.Dynamic.Core;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.BaseServices.Implementation
{
    public abstract class BaseService<TModel, TSearch, TDbEntity> : IService<TModel, TSearch> 
        where TSearch : BaseSearchObject where TDbEntity : class where TModel : class
    {
        protected readonly _220030Context Context;
        protected readonly IMapper Mapper;
        public BaseService(_220030Context context, IMapper mapper)
        {
            Context = context;
            Mapper = mapper;
        }

        public virtual async Task<Model.PagedResult<TModel>> GetAsync(TSearch search)
        {
            IEnumerable<TDbEntity> query = Context.Set<TDbEntity>();
            query = ApplyFilter(query.AsQueryable(), search);

            query = await IncludeRelatedEntitiesAsync(search, query);

            int? totalCount = null;

            if (search.IncludeTotalCount ?? false)
            {
                totalCount = query.Count();
            }

            if (!string.IsNullOrWhiteSpace(search.SortBy))
            {
                //TODO: parametrize sortBy to prevent SQL injection
                query = query.AsQueryable().OrderBy(search.SortBy);
            }

            if (search.Page.HasValue)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value);
            }

            if (search.PageSize.HasValue)
            {
                query = query.Take(search.PageSize.Value);
            }

            var list = query.Select(item => MapToResponse(item)).ToList();

            var pageResult = new Model.PagedResult<TModel>
            {
                Items = list,
                TotalCount = totalCount
            };

            return await Task.FromResult(pageResult);
        }

        private async Task<IEnumerable<TDbEntity>> IncludeRelatedEntitiesAsync(TSearch? search, IEnumerable<TDbEntity> query=null)
        {
            return query;
        }

        protected virtual IQueryable<TDbEntity> ApplyFilter(IQueryable<TDbEntity> query, TSearch? search)
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


        public virtual async Task<Model.PagedResult<TModel>> GetAllAsync(TSearch? search = null)
        {
            IEnumerable<TDbEntity> query = Context.Set<TDbEntity>();
            query = ApplyFilter(query.AsQueryable(), search);

            query = await IncludeRelatedEntitiesAsync(search, query.AsQueryable());

            int? totalCount = null;

            if (search.IncludeTotalCount ?? false)
            {
                totalCount = query.Count();
            }

            if (!string.IsNullOrWhiteSpace(search.SortBy))
            {
                //TODO: parametrize sortBy to prevent SQL injection
                query = query.AsQueryable().OrderBy(search.SortBy);
            }

            if (search.Page.HasValue)
            {
                query = query.Skip((search.Page.Value - 1) * search.PageSize.Value);
            }

            if (search.PageSize.HasValue)
            {
                query = query.Take(search.PageSize.Value);
            }

            var list = query.Select(item => MapToResponse(item)).ToList();

            var pageResult = new Model.PagedResult<TModel>
            {
                Items = list,
                TotalCount = totalCount
            };

            return await Task.FromResult(pageResult);
        }

        protected virtual async Task<IQueryable<TDbEntity>> IncludeRelatedEntitiesAsync(TSearch? search, IQueryable<TDbEntity> query = null)
        {
            // Override in derived classes to include related entities if necessary
            return await Task.FromResult(query);
        }


    }
}