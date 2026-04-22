using Azure.Core;
using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Interfaces;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using FluentValidation.Results;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.BaseServices.Implementation
{
    public abstract class BaseCRUDService<TModel, TSearch, TDbEntity, TInsert, TUpdate>
    : BaseService<TModel, TSearch, TDbEntity>, ICRUDService<TModel, TSearch, TInsert, TUpdate>
    where TModel : class 
    where TSearch : BaseSearchObject 
    where TDbEntity : class, new() 
    where TInsert : class 
    where TUpdate : class
    {

        protected readonly _220030Context _context;
        private readonly IMapper _mapper;
        protected readonly IValidator<TInsert> _insertValidator;
        protected readonly IValidator<TUpdate> _updateValidator;

        public BaseCRUDService(_220030Context context, IMapper mapper, IValidator<TInsert> insertValidator, IValidator<TUpdate> updateValidator) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
            _insertValidator = insertValidator;
            _updateValidator = updateValidator;
        }

        public virtual async Task<TModel> CreateAsync(TInsert request)
        {
            var validationResult = await _insertValidator.ValidateAsync(request);

            if (validationResult.IsValid == false)
            {
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new FluentValidation.ValidationException(errors);
            }

            var entity = new TDbEntity();
            var entityType = entity.GetType();

            var createdAtProperty = entityType.GetProperty("CreatedAt");
            if (createdAtProperty?.CanWrite == true)
            {
                createdAtProperty.SetValue(entity, DateTime.UtcNow);
            }

            MapInsertToEntity(entity, request);
            _context.Set<TDbEntity>().Add(entity);

            await BeforeInsert(entity, request);

            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }

        protected virtual async Task BeforeInsert(TDbEntity entity, TInsert request)
        {

        }


        public virtual async Task<TModel?> UpdateAsync(int id, TUpdate request)
        {
            var validationResult = await _updateValidator.ValidateAsync(request);

            if (validationResult.IsValid == false)
            {
                var errors = validationResult.Errors.Select(e => _mapper.Map<ValidationFailure>(e));
                throw new FluentValidation.ValidationException(errors);
            }

            var entity = await _context.Set<TDbEntity>().FindAsync(id);


            if (entity == null)
                throw new KeyNotFoundException($"{typeof(TDbEntity).Name} with id {id} not found.");


            MapUpdateToEntity(entity, request);

            var updatedAtProperty = entity.GetType().GetProperty("UpdatedAt");
            if (updatedAtProperty?.CanWrite == true)
            {
                updatedAtProperty.SetValue(entity, DateTime.UtcNow);
            }

            await BeforeUpdate(entity, request);

            await _context.SaveChangesAsync();
            return MapToResponse(entity);
        }

        protected virtual async Task BeforeUpdate(TDbEntity entity, TUpdate request)
        {

        }

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
                softDeleteEntity.DeletedAt = DateTime.UtcNow;
                Context.Update(entity);
            }
            else
            {
                Context.Remove(entity);
            }

            Context.SaveChanges();
        }

        public virtual async Task<bool> DeleteAsync(int id)
        {
            var entity = await _context.Set<TDbEntity>().FindAsync(id);

            if (entity == null)
                throw new KeyNotFoundException($"{typeof(TDbEntity).Name} with id {id} not found.");

            await BeforeDelete(entity);

            if (entity is ISoftDelete softDeleteEntity)
            {
                softDeleteEntity.IsDeleted = true;
                softDeleteEntity.DeletedAt = DateTime.UtcNow;
                _context.Set<TDbEntity>().Update(entity);
            }
            else
            {
                _context.Set<TDbEntity>().Remove(entity);
            }

            await _context.SaveChangesAsync();
            return true;
        }

        protected virtual async Task BeforeDelete(TDbEntity entity)
        {

        }

        protected virtual void MapUpdateToEntity(TDbEntity entity, TUpdate request)
        {
            _mapper.Map(request, entity);
        }

        protected virtual TDbEntity MapInsertToEntity(TDbEntity entity, TInsert request)
        {
            return _mapper.Map(request, entity);
        }
    }
}
