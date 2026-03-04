using Azure.Core;
using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Interfaces;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.BaseServices.Implementation
{
    public abstract class BaseCRUDService<TModel, TSearch, TDbEntity, TInsert, TUpdate> : BaseService<TModel, TSearch, TDbEntity> where TModel : class where TSearch : BaseSearchObject where TDbEntity : class
    {
        protected BaseCRUDService(_220030Context context, IMapper mapper) : base(context, mapper)
        {
        }

        public virtual TModel Insert(TInsert request)
        {
            var set = Context.Set<TDbEntity>();

            TDbEntity entity = Mapper.Map<TDbEntity>(request);

            set.Add(entity);

            BeforeInsert(request, entity);

            Context.Add(entity);
            Context.SaveChanges();

            return Mapper.Map<TModel>(entity);
        }

        public virtual void BeforeInsert(TInsert request, TDbEntity entity) { }
        

        public virtual TUpdate Update(int id, TUpdate request)
        {
            var set = Context.Set<TDbEntity>();

            var entity = set.Find(id);

            Mapper.Map(request, entity);

            BeforeUpdate(request, entity);

            Context.SaveChanges();

            return Mapper.Map<TUpdate>(entity);
        }

        public virtual void BeforeUpdate(TUpdate request, TDbEntity entity) { }

        public virtual void Delete(int id)
        {
            var entity = Context.Set<TDbEntity>().Find(id);

            if (entity == null)
            {
                throw new Exception("Unesite postojeci id");
            }

            if (entity is ISoftDelete softDeleteEntity)
            {
                softDeleteEntity.IsDeleted = true;
                softDeleteEntity.DeletedAt = DateTime.Now;
                Context.Update(entity);
            }
            else
            {
                Context.Remove(entity);
            }

            Context.SaveChanges();
        }
    }
}
