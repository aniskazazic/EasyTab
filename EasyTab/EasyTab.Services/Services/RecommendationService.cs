using System.Linq.Expressions;
using EasyTab.Model.Models;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.ReservationStateMachine;
using Microsoft.EntityFrameworkCore;
using static EasyTab.Services.Services.RecommendationConstants;

namespace EasyTab.Services.Services;

public sealed class RecommendationService(_220030Context context, ICurrentUserService currentUser)
    : IRecommendationService
{
    public async Task<IReadOnlyList<RecommendedLocaleResponse>> GetRecommendedAsync(
        CancellationToken cancellationToken = default)
    {
        var userId = currentUser.UserId;
        var popularity = context.Reservations
            .Where(r => r.ReservationState == ConfirmedReservationState.StateName ||
                        r.ReservationState == CompletedReservationState.StateName)
            .GroupBy(r => r.Table.LocaleId)
            .Select(g => new LocalePopularity { LocaleId = g.Key, Count = g.Count() });
        var maximumPopularity = await popularity
            .Where(item => context.Locales.Any(l => l.Id == item.LocaleId && !l.IsDeleted))
            .Select(item => (int?)item.Count).MaxAsync(cancellationToken) ?? 0;

        var features = BuildFeatures(popularity, maximumPopularity);
        var completed = context.Reservations
            .Where(r => r.UserId == userId && r.ReservationState == CompletedReservationState.StateName)
            .GroupBy(r => r.Table.LocaleId)
            .Select(g => new { LocaleId = (int?)g.Key, Count = g.Count() });
        var favourites = context.Favourites
            .Where(f => f.UserId == userId && f.IsActive)
            .Select(f => new { LocaleId = (int?)f.LocaleId }).Distinct();
        var reviews = context.Reviews
            .Where(r => r.UserId == userId && !r.IsDeleted)
            .GroupBy(r => r.LocaleId)
            .Select(g => new
            {
                LocaleId = (int?)g.Key,
                Weight = g.Sum(r => (r.Rating - NeutralRating) / ReviewRatingRange * ReviewWeight)
            });
        var interactions =
            from feature in features
            join reservation in completed on feature.Id equals reservation.LocaleId into reservationGroup
            from reservation in reservationGroup.DefaultIfEmpty()
            join favourite in favourites on feature.Id equals favourite.LocaleId into favouriteGroup
            from favourite in favouriteGroup.DefaultIfEmpty()
            join review in reviews on feature.Id equals review.LocaleId into reviewGroup
            from review in reviewGroup.DefaultIfEmpty()
            where reservation.LocaleId != null || favourite.LocaleId != null || review.LocaleId != null
            select new
            {
                feature.CategoryId,
                feature.CityId,
                feature.Rating,
                feature.Popularity,
                Weight = (((int?)reservation.Count ?? 0) > CompletedReservationCap
                    ? CompletedReservationCap : (int?)reservation.Count ?? 0) * CompletedReservationWeight +
                    (favourite.LocaleId == null ? 0 : FavouriteWeight) +
                    ((double?)review.Weight ?? 0)
            };

        var categoryProfile = await interactions.GroupBy(i => i.CategoryId)
            .Select(g => new { Id = g.Key, Weight = g.Sum(i => i.Weight) })
            .ToDictionaryAsync(x => x.Id, x => x.Weight, cancellationToken);
        var cityProfile = await interactions.GroupBy(i => i.CityId)
            .Select(g => new { Id = g.Key, Weight = g.Sum(i => i.Weight) })
            .ToDictionaryAsync(x => x.Id, x => x.Weight, cancellationToken);
        var numericProfile = await interactions.GroupBy(i => 1)
            .Select(g => new
            {
                Rating = g.Sum(i => i.Weight * i.Rating),
                Popularity = g.Sum(i => i.Weight * i.Popularity)
            }).SingleOrDefaultAsync(cancellationToken);
        var ratingProfile = numericProfile?.Rating ?? 0;
        var popularityProfile = numericProfile?.Popularity ?? 0;
        var profileNorm = Math.Sqrt(categoryProfile.Values.Sum(w => w * w) +
            cityProfile.Values.Sum(w => w * w) + ratingProfile * ratingProfile +
            popularityProfile * popularityProfile);

        var candidates = features.Where(f =>
            !completed.Any(r => r.LocaleId == f.Id) &&
            !favourites.Any(favourite => favourite.LocaleId == f.Id) &&
            !reviews.Any(r => r.LocaleId == f.Id));
        var selected = new List<RankedLocale>();
        if (profileNorm > 0)
        {
            var scored = candidates.Select(BuildDotProduct(categoryProfile, cityProfile,
                ratingProfile, popularityProfile));
            selected = await scored.Where(s => s.DotProduct > 0)
                .Select(s => new RankedLocale
                {
                    Id = s.Feature.Id,
                    Rating = s.Feature.Rating,
                    Popularity = s.Feature.Popularity,
                    Score = s.DotProduct / (profileNorm * Math.Sqrt(OneHotSquaredNorm +
                        s.Feature.Rating * s.Feature.Rating + s.Feature.Popularity * s.Feature.Popularity)),
                    IsPersonalized = true
                })
                .OrderByDescending(s => s.Score).ThenByDescending(s => s.Rating)
                .ThenByDescending(s => s.Popularity).ThenBy(s => s.Id)
                .Take(ResultLimit).ToListAsync(cancellationToken);
        }

        if (selected.Count < ResultLimit)
        {
            var selectedIds = selected.Select(s => s.Id).ToArray();
            var fallback = await candidates.Where(f => !selectedIds.Contains(f.Id))
                .Select(f => new RankedLocale
                {
                    Id = f.Id,
                    Rating = f.Rating,
                    Popularity = f.Popularity,
                    Score = ColdRatingWeight * f.Rating + ColdPopularityWeight * f.Popularity,
                    IsPersonalized = false
                })
                .OrderByDescending(s => s.Score).ThenByDescending(s => s.Rating)
                .ThenByDescending(s => s.Popularity).ThenBy(s => s.Id)
                .Take(ResultLimit - selected.Count).ToListAsync(cancellationToken);
            selected.AddRange(fallback);
        }

        var ids = selected.Select(s => s.Id).ToArray();
        var details = await context.Locales.AsNoTracking().Where(l => ids.Contains(l.Id))
            .Select(l => new { l.Id, l.Name, l.CategoryId, l.CityId,
                CategoryName = l.Category.Name, CityName = l.City.Name, l.Logo })
            .ToDictionaryAsync(l => l.Id, cancellationToken);
        return selected.Select(s =>
        {
            var locale = details[s.Id];
            var explanation = s.IsPersonalized
                ? Explain(categoryProfile.GetValueOrDefault(locale.CategoryId),
                    cityProfile.GetValueOrDefault(locale.CityId),
                    ratingProfile * s.Rating, popularityProfile * s.Popularity,
                    locale.CategoryName, locale.CityName)
                : ColdExplanation;
            return new RecommendedLocaleResponse(locale.Id, locale.Name, locale.CategoryName,
                locale.CityName, s.Rating * MaximumRating, locale.Logo, explanation, s.Score);
        }).ToList();
    }

    private IQueryable<LocaleFeature> BuildFeatures(
        IQueryable<LocalePopularity> popularity, int maximumPopularity)
    {
        var ratings = context.Reviews.Where(r => !r.IsDeleted)
            .GroupBy(r => r.LocaleId)
            .Select(g => new { LocaleId = g.Key, Average = g.Average(r => (double)r.Rating) });
        return from locale in context.Locales.AsNoTracking().Where(l => !l.IsDeleted)
            join rating in ratings on locale.Id equals rating.LocaleId into ratingGroup
            from rating in ratingGroup.DefaultIfEmpty()
            join count in popularity on locale.Id equals count.LocaleId into countGroup
            from count in countGroup.DefaultIfEmpty()
            select new LocaleFeature
            {
                Id = locale.Id,
                CategoryId = locale.CategoryId,
                CityId = locale.CityId,
                Rating = ((double?)rating.Average ?? 0) / MaximumRating,
                Popularity = maximumPopularity == 0 ? 0 : (double)((int?)count.Count ?? 0) / maximumPopularity
            };
    }

    private static Expression<Func<LocaleFeature, DotProductResult>> BuildDotProduct(
        IReadOnlyDictionary<int, double> categories, IReadOnlyDictionary<int, double> cities,
        double rating, double popularity)
    {
        var feature = Expression.Parameter(typeof(LocaleFeature), "feature");
        Expression dot = Expression.Add(
            LookupWeight(categories, Expression.Property(feature, nameof(LocaleFeature.CategoryId))),
            LookupWeight(cities, Expression.Property(feature, nameof(LocaleFeature.CityId))));
        dot = Expression.Add(dot, Expression.Multiply(Expression.Constant(rating),
            Expression.Property(feature, nameof(LocaleFeature.Rating))));
        dot = Expression.Add(dot, Expression.Multiply(Expression.Constant(popularity),
            Expression.Property(feature, nameof(LocaleFeature.Popularity))));
        var result = Expression.MemberInit(Expression.New(typeof(DotProductResult)),
            Expression.Bind(typeof(DotProductResult).GetProperty(nameof(DotProductResult.Feature))!, feature),
            Expression.Bind(typeof(DotProductResult).GetProperty(nameof(DotProductResult.DotProduct))!, dot));
        return Expression.Lambda<Func<LocaleFeature, DotProductResult>>(result, feature);
    }

    private static Expression LookupWeight(IReadOnlyDictionary<int, double> weights, Expression id)
    {
        Expression result = Expression.Constant(0.0);
        foreach (var (key, value) in weights.Where(w => w.Value != 0).OrderBy(w => w.Key))
            result = Expression.Add(result,
                Expression.Condition(Expression.Equal(id, Expression.Constant(key)),
                    Expression.Constant(value), Expression.Constant(0.0)));
        return result;
    }

    private static string Explain(double category, double city, double rating, double popularity,
        string categoryName, string cityName)
    {
        var contributions = new[]
        {
            (Value: category, Text: $"kategorija „{categoryName}“ odgovara vašim dosadašnjim izborima"),
            (Value: city, Text: $"grad „{cityName}“ odgovara vašim dosadašnjim izborima"),
            (Value: rating, Text: "prosječna ocjena lokala odgovara vašem profilu"),
            (Value: popularity, Text: "popularnost lokala odgovara vašem profilu")
        };
        return "Preporučeno jer " + string.Join(" i ", contributions.Where(c => c.Value > 0)
            .OrderByDescending(c => c.Value).Take(ExplanationFeatureLimit).Select(c => c.Text)) + ".";
    }

    private sealed class LocalePopularity
    {
        public int LocaleId { get; init; }
        public int Count { get; init; }
    }

    private sealed class LocaleFeature
    {
        public int Id { get; init; }
        public int CategoryId { get; init; }
        public int CityId { get; init; }
        public double Rating { get; init; }
        public double Popularity { get; init; }
    }

    private sealed class DotProductResult
    {
        public LocaleFeature Feature { get; init; } = null!;
        public double DotProduct { get; init; }
    }

    private sealed class RankedLocale
    {
        public int Id { get; init; }
        public double Rating { get; init; }
        public double Popularity { get; init; }
        public double Score { get; init; }
        public bool IsPersonalized { get; init; }
    }
}
