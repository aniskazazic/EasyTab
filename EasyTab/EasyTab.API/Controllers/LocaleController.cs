using EasyTab.API.Controllers.BaseControllers;
using EasyTab.API.Filters;
using EasyTab.Model.Models;
using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Model.Responses;
using EasyTab.Services.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Controllers
{
    [ApiController]
    [Route("[controller]")]
    [Authorization]
    public class LocaleController :BaseCRUDController<Locales, LocaleSearchObject, LocaleInsertRequest, LocaleUpdateRequest>
    {
        private readonly IRecommendationService _recommendationService;

        public LocaleController(ILocaleService service, IRecommendationService recommendationService) : base(service)
        {
            _recommendationService = recommendationService;
        }

        /// <summary>Vraća do tri lokala uz objašnjenje preporuke za prijavljenog korisnika.</summary>
        [HttpGet("recommended")]
        [Authorization(RoleNames.Korisnik)]
        [ProducesResponseType(typeof(IReadOnlyList<RecommendedLocaleResponse>), StatusCodes.Status200OK)]
        [ProducesResponseType(StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(StatusCodes.Status403Forbidden)]
        public async Task<ActionResult<IReadOnlyList<RecommendedLocaleResponse>>> Recommended(
            CancellationToken cancellationToken)
        {
            return Ok(await _recommendationService.GetRecommendedAsync(cancellationToken));
        }

        [Authorization(RoleNames.Admin, RoleNames.Vlasnik)]
        public override Task<Locales> Create([FromBody] LocaleInsertRequest request) => base.Create(request);

        [Authorization(RoleNames.Admin, RoleNames.Vlasnik)]
        public override Task<Locales?> Update(int id, [FromBody] LocaleUpdateRequest request) => base.Update(id, request);

        [HttpGet("{id}/deactivation-preview")]
        [Authorization(RoleNames.Admin)]
        public async Task<ActionResult<LocaleDeactivationPreviewResponse>> DeactivationPreview(int id, CancellationToken cancellationToken)
            => Ok(await ((ILocaleService)_service).GetDeactivationPreviewAsync(id, cancellationToken));

        [Authorization(RoleNames.Admin)]
        public override Task<bool> Delete(int id) => base.Delete(id);

    }
}
