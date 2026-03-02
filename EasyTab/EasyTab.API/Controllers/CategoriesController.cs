using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CategoriesController : BaseCRUDController<Categories, CategorySearchObject, CategoryInsertRequest, CategoryUpdateRequest>
    {
        public CategoriesController(ICategoryService service) : base(service) { }
    }
}
