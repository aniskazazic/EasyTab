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
using System.Linq.Expressions;
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

        public virtual async Task<Model.PagedResult<TModel>> GetAsync(TSearch search)
        {
            IQueryable<TDbEntity> query = Context.Set<TDbEntity>();
            query = ApplyFilter(query, search);

            var page = Math.Max(search.Page ?? 1, 1);
            var pageSize = Math.Clamp(search.PageSize ?? DefaultPageSize, 1, MaxPageSize);
            search.Page = page;
            search.PageSize = pageSize;

            int? totalCount = null;
            if (search.IncludeTotalCount ?? false)
                totalCount = await query.CountAsync();

            query = ApplySort(query, search);

            query = query
                .Skip((int)Math.Min(((long)page - 1) * pageSize, int.MaxValue))
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

        protected virtual IQueryable<TDbEntity> ApplySort(IQueryable<TDbEntity> query, TSearch search)
        {
            var sortColumn = AllowedSortColumns.Contains(search.SortBy ?? string.Empty) &&
                             typeof(TDbEntity).GetProperty(
                                 search.SortBy!,
                                 BindingFlags.Instance | BindingFlags.Public | BindingFlags.IgnoreCase) != null
                ? search.SortBy!
                : "Id";

            if (!string.IsNullOrWhiteSpace(search.SortBy) ||
                !ContainsOrdering(query.Expression))
            {
                query = query.OrderBy(sortColumn);
            }

            return query;
        }

        private static bool ContainsOrdering(Expression expression)
        {
            if (expression is MethodCallExpression methodCall)
            {
                if (methodCall.Method.Name is "OrderBy" or "OrderByDescending" or
                    "ThenBy" or "ThenByDescending")
                {
                    return true;
                }

                return methodCall.Arguments.Any(ContainsOrdering);
            }

            return expression is UnaryExpression unary &&
                   ContainsOrdering(unary.Operand);
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
