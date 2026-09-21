namespace EasyTab.Services.Interfaces
{
    public interface ILocaleAccessService
    {
        Task EnsureCanManageLocaleAsync(int localeId);
        Task EnsureCanManageLocaleAsOwnerAsync(int localeId);
    }
}
