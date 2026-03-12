using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers.BaseControllers
{
    [ApiController]
    [Route("[controller]")]
    public class BaseCRUDController<TModel, TSearch, TInsert, TUpdate> : BaseController<TModel, TSearch>
        where TSearch : BaseSearchObject, new() 
        where TModel : class, new()
        where TInsert : class
        where TUpdate : class
    {
        protected new readonly ICRUDService<TModel, TSearch, TInsert, TUpdate> _service;

        public BaseCRUDController(ICRUDService<TModel, TSearch, TInsert, TUpdate> service) : base(service)
        {
            _service = service;
        }

        [HttpPost]
        public virtual async Task<TModel> Create([FromBody] TInsert request)
        {
            return await _service.CreateAsync(request);
        }

        [HttpPut("{id}")]
        public virtual async Task<TModel?> Update(int id, [FromBody] TUpdate request)
        {
            return await _service.UpdateAsync(id, request);
        }

        [HttpDelete("{id}")]
        public virtual async Task<bool> Delete(int id)
        {
            return await _service.DeleteAsync(id);
        }
    }
}
