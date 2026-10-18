using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.Interfaces;
using EasyTab.Services.Services;
using Microsoft.AspNetCore.Mvc;
using EasyTab.API.Filters;


namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReviewsController : BaseCRUDController<Reviews, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        private readonly IReviewService _reviewService;
        public ReviewsController(IReviewService service) : base(service) 
        { 
            _reviewService = service;
        }

        [HttpGet("can-review")]
        [Authorization]
        public async Task<IActionResult> CanReview([FromQuery] int localeId)
        {
            var result = await _reviewService.CanReviewAsync(localeId);
            return Ok(result);
        }

        [HttpGet("average/{localeId}")]
        public async Task<IActionResult> GetAverageRating(int localeId)
        {
            var result = await _reviewService.GetAverageRatingAsync(localeId);
            return Ok(result);
        }

        [HttpGet("rating-counts/{localeId}")]
        public async Task<IActionResult> GetRatingCounts(int localeId)
        {
            var result = await _reviewService.GetRatingCountsAsync(localeId);
            return Ok(result);
        }

        [HttpDelete("soft-delete/{id}")]
        public async Task<IActionResult> SoftDelete(int id)
        {
            await _reviewService.DeleteAsync(id);
            return Ok(new { Message = "Recenzija obrisana!" });
        }

        [HttpGet("by-locale/{localeId}")]
        public async Task<IActionResult> GetReviewsByLocaleId(int localeId)
        {
            var reviews = await _reviewService.GetByLocaleId(localeId);
            return Ok(reviews);
        }
    }
}
