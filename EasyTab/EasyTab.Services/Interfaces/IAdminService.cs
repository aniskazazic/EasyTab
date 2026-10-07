using EasyTab.Model.Requests;
using EasyTab.Model.Responses;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IAdminService 
    {
        Task<AdminStatsResponse> GetStats();
        Task<AdminAnalyticsResponse> GetAnalytics();
        Task<AdminLocalePageResponse> GetAllLocales(string? search, bool showDeleted, int page, int pageSize);
        Task UpdateLocale(int id, AdminUpdateLocaleRequest request);
        Task ReactivateLocale(int id);
    }
}
