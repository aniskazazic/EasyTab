using EasyTab.Model.Models;

namespace EasyTab.Services.Interfaces;

public interface IRecommendationService
{
    Task<IReadOnlyList<RecommendedLocaleResponse>> GetRecommendedAsync(CancellationToken cancellationToken = default);
}
