using EasyTab.Model;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers.BaseControllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorize]
    public class BaseController<TModel, TSearch> : ControllerBase where TSearch : BaseSearchObject
    {
        protected IService<TModel, TSearch> _service;

        public BaseController(IService<TModel, TSearch> service)
        {
            _service = service;
        }

        [HttpGet]
        public virtual PagedResult<TModel> GetPaged([FromQuery] TSearch searchObject)
        {
            return _service.GetPaged(searchObject);
        }

        [HttpGet("{id}")]
        public virtual TModel GetById(int id){
            return _service.GetById(id);
        }
}
}
