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

        public PagedResult<TModel> GetPaged(TSearch search)
        {
            List<TModel> result = new List<TModel>();

            var querry = Context.Set<TDbEntity>().AsQueryable();

            querry = AddFilter(querry, search);

            int count = querry.Count();

            if (search?.Page.HasValue == true && search?.PageSize.HasValue == true)
            {
                querry = querry.Skip(search.Page.Value * search.PageSize.Value).Take(search.PageSize.Value);
            }

            var list = querry.ToList();

            var resultList = Mapper.Map(list, result);

            PagedResult<TModel> response = new PagedResult<TModel>
            {
                Count = count,
                ResultList = resultList
            };
            return response;
        }

        public virtual IQueryable<TDbEntity> AddFilter(IQueryable<TDbEntity> query, TSearch search)
        {
            return query;
        }

        public TModel GetById(int id)
        {
            var entity = Context.Set<TDbEntity>().Find(id);

            if (entity != null)
            {
                return Mapper.Map<TModel>(entity);
            }
            else
            {
                return null;
            }
        }
    }
}