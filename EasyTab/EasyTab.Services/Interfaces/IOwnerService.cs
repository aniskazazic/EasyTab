using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using EasyTab.Model.Responses;

namespace EasyTab.Services.Interfaces
{
    public interface IOwnerService
    {
        Task<int> GetTodaysReservations(int localeId);
        Task<int> GetTodaysGuests(int localeId);
        Task<int> GetActiveTables(int localeId);
        Task<int> GetTotalTables(int localeId);
        Task<OwnerLocaleResponse> GetMyLocale(int localeId);
        Task<List<TableDistributionResponse>> GetTableDistribution(int localeId);
        Task<OwnerReservationsPageResponse> GetAllReservations(int userId, string? q, DateTime? date, int page, int pageSize);
        Task<bool> CheckIfOwner(int localeId, int userId);
        Task<bool> CheckIfOwnerOrWorker(int localeId, int userId);
    }
}
