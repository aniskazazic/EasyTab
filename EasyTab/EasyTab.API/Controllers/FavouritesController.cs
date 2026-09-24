using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class FavouritesController : BaseController<Favourites, FavouriteSearchObject>
    {
        private readonly IFavouriteService _service;

        public FavouritesController(IFavouriteService service) : base(service)
        {
            _service = service;
        }

        [HttpPost("add")]
        public IActionResult AddToFavourites([FromQuery] int localeId)
        {
            var result = _service.AddToFavourites(localeId);
            return Ok(result);
        }

        [HttpDelete("remove")]
        public IActionResult RemoveFromFavourites([FromQuery] int localeId)
        {
            _service.RemoveFromFavourites(localeId);
            return Ok(new { Message = "Lokal uklonjen iz favorita!" });
        }

        [HttpGet("is-favourited")]
        public IActionResult IsFavourited([FromQuery] int localeId)
        {
            var result = _service.IsFavourited(localeId);
            return Ok(result);
        }

        [HttpGet("by-user/{userId}")]
        public IActionResult GetByUser()
        {
            var result = _service.GetByUser();
            return Ok(result);
        }
    }
}
