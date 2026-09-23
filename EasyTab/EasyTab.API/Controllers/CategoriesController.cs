using EasyTab.API.Controllers.BaseControllers;
using EasyTab.API.Filters;
using EasyTab.Model;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization]
    public class CategoriesController : BaseCRUDController<Categories, CategorySearchObject, CategoryUpsertRequest, CategoryUpsertRequest>
    {
        public CategoriesController(ICategoryService service) : base(service) { }

        [Authorization("Admin")]
        public override Task<Categories> Create([FromBody] CategoryUpsertRequest request) => base.Create(request);

        [Authorization("Admin")]
        public override Task<Categories?> Update(int id, [FromBody] CategoryUpsertRequest request) => base.Update(id, request);

        [Authorization("Admin")]
        public override Task<bool> Delete(int id) => base.Delete(id);

    }
}
