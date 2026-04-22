using EasyTab.Model.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.QueryOptimization
{
    public interface IQueryOptimizationService
    {
        Task<Locales> AsNoTrackingBadQuerry();
        Task<Locales> AsNoTrackingGoodQuerry();
        Task<List<Locales>> GetFilteredLocalesBadQuerry();
        Task<List<Locales>> GetFilteredLocalesGoodQuerry();
        Task<List<string>> GetFullNamesBadQuerry();
        Task<List<string>> GetFullNamesGoodQuerry();
        Task<List<Users>> SplittingQueries();
        Task<List<Locales>> UsingSqlQueries();

    }
}
