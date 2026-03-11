using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IOwnerService
    {
        Task<int> GetTodaysReservations(int localeId);
        Task<int> GetTodaysGuests(int localeId);
        Task<int> GetActiveTables(int localeId);
        Task<int> GetTotalTables(int localeId);
        Task<object> GetMyLocale(int localeId);
        Task<object> GetTableDistribution(int localeId);
        Task<object> GetAllReservations(int userId, string? q, DateTime? date, int page, int pageSize);
        Task<bool> CheckIfOwner(int localeId, int userId);
        Task<bool> CheckIfOwnerOrWorker(int localeId, int userId);
    }
}
