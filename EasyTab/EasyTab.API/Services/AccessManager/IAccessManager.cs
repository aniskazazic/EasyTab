using EasyTab.Model.Access;

namespace EasyTab.API.Services.AccessManager
{
    public interface IAccessManager
    {
        Task<UserLoginResponse> LoginAsync(UserLoginRequest request);
        Task<UserLoginResponse> LoginWithRefreshTokenAsync(RefreshAccessTokenRequest request);
        Task LogoutAsync(int userId);
    }
}
