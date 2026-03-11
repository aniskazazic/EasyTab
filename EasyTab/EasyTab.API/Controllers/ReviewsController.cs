using EasyTab.API.Controllers.BaseControllers;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.Interfaces;
using EasyTab.Services.Services;
using Microsoft.AspNetCore.Mvc;


namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ReviewsController : BaseCRUDController<Reviews, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        public IReviewService _service;
        public ReviewsController(IReviewService service) : base(service) 
        { 
            _service = service;
        }

        [HttpGet("average/{localeId}")]
        public IActionResult GetAverageRating(int localeId)
        {
            var result = _service.GetAverageRating(localeId);
            return Ok(result);
        }

        [HttpGet("rating-counts/{localeId}")]
        public IActionResult GetRatingCounts(int localeId)
        {
            var result = _service.GetRatingCounts(localeId);
            return Ok(result);
        }

        [HttpDelete("soft-delete/{id}")]
        public IActionResult SoftDelete(int id)
        {
            _service.DeleteAsync(id);
            return Ok(new { Message = "Recenzija obrisana!" });
        }
    }
}
