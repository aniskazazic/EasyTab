using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CategoriesController : BaseCRUDController<Categories, CategorySearchObject, CategoryUpsertRequest, CategoryUpsertRequest>
    {
        public CategoriesController(ICategoryService service) : base(service) { }

    }
}
