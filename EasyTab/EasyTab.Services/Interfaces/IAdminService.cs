using EasyTab.Model.Requests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IAdminService 
    {
        Task<object> GetStats();
        Task<object> GetAnalytics();
        Task<object> GetAllLocales(string? search, bool showDeleted, int page, int pageSize);
        Task UpdateLocale(int id, AdminUpdateLocaleRequest request);
        Task ReactivateLocale(int id);
    }
}
