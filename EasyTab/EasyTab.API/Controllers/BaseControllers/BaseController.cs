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
    public class BaseController<TModel, TSearch> : ControllerBase where TSearch : BaseSearchObject, new()
    {
        protected readonly IService<TModel, TSearch> _service;

        public BaseController(IService<TModel, TSearch> service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<PagedResult<TModel>> Get([FromQuery] TSearch? search = null)
        {
            return await _service.GetAsync(search ?? new TSearch());
        }

        [HttpGet("{id}")]
        public async Task<TModel?> GetById(int id) 
        {
            return await _service.GetByIdAsync(id);
        }
    }
}
