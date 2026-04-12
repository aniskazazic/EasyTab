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
        [AllowAnonymous]
        public IActionResult React(ReactionInsertRequest request)
        {
            var result = _service.React(request.ReviewId, request.UserId,   request.IsLike);
            return Ok(result);
        }

        [HttpDelete]
        [AllowAnonymous]
        public IActionResult RemoveReaction([FromQuery] int reviewId, [FromQuery] int userId)
        {
            _service.RemoveReaction(reviewId, userId);
            return Ok(new { Message = "Reakcija uklonjena!" });
        }

        [HttpGet("count/{reviewId}")]
        public IActionResult GetReactionCounts(int reviewId)
        {
            var result = _service.GetReactionCounts(reviewId);
            return Ok(result);
        }
    }
}
