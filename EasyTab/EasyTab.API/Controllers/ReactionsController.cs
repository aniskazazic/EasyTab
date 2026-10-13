using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReactionsController : BaseController<Reactions, ReactionSearchObject>
    {
        public IReactionService _service;

        public ReactionsController(IReactionService service) : base(service)
        {
            _service = service;
        }

        [HttpPost]
        public async Task<IActionResult> React(ReactionInsertRequest request)
        {
            var result = await _service.ReactAsync(request.ReviewId, request.IsLike);
            return Ok(result);
        }

        [HttpDelete]
        public async Task<IActionResult> RemoveReaction([FromQuery] int reviewId)
        {
            await _service.RemoveReactionAsync(reviewId);
            return Ok(new { Message = "Reakcija uklonjena!" });
        }

        [HttpGet("count/{reviewId}")]
        public async Task<IActionResult> GetReactionCounts(int reviewId)
        {
            var result = await _service.GetReactionCountsAsync(reviewId);
            return Ok(result);
        }
    }
}
