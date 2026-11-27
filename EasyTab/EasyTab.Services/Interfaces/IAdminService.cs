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
        Task<AdminAnalyticsResponse> GetAnalytics();
        Task ReactivateLocale(int id);
    }
}
