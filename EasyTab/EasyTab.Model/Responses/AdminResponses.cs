using System;
using System.Collections.Generic;

namespace EasyTab.Model.Responses;

public sealed class AdminLocalePageResponse
{
    public List<AdminLocaleListItemResponse> Items { get; set; } = new();
    public int TotalCount { get; set; }
}

public sealed class AdminLocaleListItemResponse
{
    public int Id { get; set; }
    public string LocaleName { get; set; } = null!;
    public string City { get; set; } = null!;
    public string Country { get; set; } = null!;
    public string Category { get; set; } = null!;
    public string Address { get; set; } = null!;
    public bool IsDeleted { get; set; }
    public int CountryId { get; set; }
    public int CityId { get; set; }
    public int CategoryId { get; set; }
}

public sealed class AdminAnalyticsResponse
{
    public int[] UserStatsData { get; set; } = Array.Empty<int>();
    public int[] UserRoleData { get; set; } = Array.Empty<int>();
    public int[] LocaleCategoryData { get; set; } = Array.Empty<int>();
    public int[] LocaleCountyData { get; set; } = Array.Empty<int>();
    public string[] CountyNames { get; set; } = Array.Empty<string>();
}

public sealed class AdminStatsResponse
{
    public int CountOfUsers { get; set; }
    public int CountOfDeletedUsers { get; set; }
    public int CountOfActiveUsers { get; set; }
    public int CountOfLocales { get; set; }
    public int CountOfActiveReservations { get; set; }
    public int CountOfPastReservations { get; set; }
    public int CountOfCountries { get; set; }
    public int CountOfCities { get; set; }
    public int CountOfCategories { get; set; }
}
