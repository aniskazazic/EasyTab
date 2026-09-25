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
using System.Reflection;
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

        protected const int MaxPageSize = 100;
        private const int DefaultPageSize = 10;

        private static readonly HashSet<string> AllowedSortColumns = new(StringComparer.OrdinalIgnoreCase)
        {
            "Id", "Name", "CreatedAt", "DateAdded", "ReservationDate", "StartTime",
            "Username", "FirstName", "LastName", "Email", "Rating", "IsDeleted"
        };

        public virtual Task<Model.PagedResult<TModel>> GetAsync(TSearch search)
        {
            return ExecutePagedAsync(search);
        }

        private async Task<Model.PagedResult<TModel>> ExecutePagedAsync(TSearch search)
        {
            IQueryable<TDbEntity> query = Context.Set<TDbEntity>();
            query = ApplyFilter(query, search);
            query = await IncludeRelatedEntitiesAsync(search, query);

            var page = Math.Max(search.Page ?? 1, 1);
            var pageSize = Math.Clamp(search.PageSize ?? DefaultPageSize, 1, MaxPageSize);
            search.Page = page;
            search.PageSize = pageSize;

            int? totalCount = null;
            if (search.IncludeTotalCount ?? false)
                totalCount = await query.CountAsync();

            var sortColumn = AllowedSortColumns.Contains(search.SortBy ?? string.Empty) &&
                             typeof(TDbEntity).GetProperty(
                                 search.SortBy!,
                                 BindingFlags.Instance | BindingFlags.Public | BindingFlags.IgnoreCase) != null
                ? search.SortBy!
                : "Id";

            query = query.OrderBy(sortColumn)
                .Skip((page - 1) * pageSize)
                .Take(pageSize);

            var entities = await query.ToListAsync();
            var list = entities.Select(MapToResponse).ToList();

            return new Model.PagedResult<TModel>
            {
                Items = list,
                TotalCount = totalCount
            };
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


        public virtual Task<Model.PagedResult<TModel>> GetAllAsync(TSearch? search = null)
        {
            search ??= Activator.CreateInstance<TSearch>()
                ?? throw new InvalidOperationException($"Unable to create {typeof(TSearch).Name}.");

            return ExecutePagedAsync(search);
        }

        protected virtual async Task<IQueryable<TDbEntity>> IncludeRelatedEntitiesAsync(TSearch? search, IQueryable<TDbEntity> query = null)
        {
            // Override in derived classes to include related entities if necessary
            return await Task.FromResult(query);
        }


    }
}