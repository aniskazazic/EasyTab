using System;

namespace EasyTab.Model.Responses;

public sealed class AdminAnalyticsResponse
{
    public int[] UserStatsData { get; set; } = Array.Empty<int>();
    /// <summary>
    /// Broj aktivnih korisnika po međusobno isključivim kategorijama [vlasnik, radnik, korisnik, administrator].
    /// Svaki korisnik je brojan jednom (prednost: administrator, vlasnik, radnik), pa je zbir jednak UserStatsData[0].
    /// </summary>
    public int[] UserRoleData { get; set; } = Array.Empty<int>();
    public string[] UserRoleLabels { get; set; } = Array.Empty<string>();
    public int[] LocaleCategoryData { get; set; } = Array.Empty<int>();
    public int[] LocaleCountyData { get; set; } = Array.Empty<int>();
    public string[] CountyNames { get; set; } = Array.Empty<string>();
}
