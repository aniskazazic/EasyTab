namespace EasyTab.Model.Models;

/// <summary>Lokal preporučen korisniku, uz skor i razlog preporuke.</summary>
public sealed record RecommendedLocaleResponse(
    int Id,
    string Name,
    string CategoryName,
    string CityName,
    double AverageRating,
    string? Logo,
    string Explanation,
    double Score);
