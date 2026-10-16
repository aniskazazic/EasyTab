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
    public class ReactionsController : BaseController<Reactions, ReactionSearchObject>
    {
        private readonly IReactionService _reactionService;

        public ReactionsController(IReactionService service) : base(service)
        {
            _reactionService = service;
        }

        [HttpPost]
        public async Task<IActionResult> React(ReactionInsertRequest request)
        {
            var result = await _reactionService.ReactAsync(request.ReviewId, request.IsLike);
            return Ok(result);
        }

        [HttpDelete]
        public async Task<IActionResult> RemoveReaction([FromQuery] int reviewId)
        {
            await _reactionService.RemoveReactionAsync(reviewId);
            return Ok(new { Message = "Reakcija uklonjena!" });
        }

        [HttpGet("count/{reviewId}")]
        public async Task<IActionResult> GetReactionCounts(int reviewId)
        {
            var result = await _reactionService.GetReactionCountsAsync(reviewId);
            return Ok(result);
        }
    }
}
