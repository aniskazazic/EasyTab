namespace EasyTab.Services.Services;

internal static class RecommendationConstants
{
    public const int ResultLimit = 3;
    public const int CompletedReservationCap = 5;
    public const double CompletedReservationWeight = 1.0;
    public const double FavouriteWeight = 1.5;
    public const double NeutralRating = 3.0;
    public const double ReviewRatingRange = 2.0;
    public const double ReviewWeight = 2.0;
    public const double MaximumRating = 5.0;
    public const double ColdRatingWeight = 0.5;
    public const double ColdPopularityWeight = 0.5;
    public const double OneHotSquaredNorm = 2.0;
    public const int ExplanationFeatureLimit = 2;
    public const string ColdExplanation = "Najpopularniji i najbolje ocijenjeni lokali";
}
