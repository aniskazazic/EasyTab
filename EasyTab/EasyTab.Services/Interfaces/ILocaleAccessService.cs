namespace EasyTab.Services.Interfaces
{
    public interface ILocaleAccessService
    {
        IQueryable<int> GetAccessibleLocaleIds();
        Task EnsureCanManageLocaleAsync(int localeId);
        Task EnsureCanManageLocaleAsOwnerAsync(int localeId);
        Task<List<int>> GetLocaleManagerUserIdsAsync(int localeId);
    }
}
