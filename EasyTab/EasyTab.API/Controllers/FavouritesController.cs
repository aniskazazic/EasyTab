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
        public async Task<IActionResult> AddToFavourites([FromQuery] int localeId)
        {
            var result = await _service.AddToFavouritesAsync(localeId);
            return Ok(result);
        }

        [HttpDelete("remove")]
        public async Task<IActionResult> RemoveFromFavourites([FromQuery] int localeId)
        {
            await _service.RemoveFromFavouritesAsync(localeId);
            return Ok(new { Message = "Lokal uklonjen iz favorita!" });
        }

        [HttpGet("is-favourited")]
        public async Task<IActionResult> IsFavourited([FromQuery] int localeId)
        {
            var result = await _service.IsFavouritedAsync(localeId);
            return Ok(result);
        }

        [HttpGet("by-user/")]
        public async Task<IActionResult> GetByUser()
        {
            var result = await _service.GetByUserAsync();
            return Ok(result);
        }
    }
}
