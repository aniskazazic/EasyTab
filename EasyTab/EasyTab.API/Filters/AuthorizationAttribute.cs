using EasyTab.API.Services.AccessManager;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace EasyTab.API.Filters
{
    public class AuthorizationAttribute : TypeFilterAttribute
    {
        public AuthorizationAttribute(params string[] roles) : base(typeof(AuthorizationFilter))
        {
            Arguments = new object[] { roles };
        }
        public class AuthorizationFilter : IAuthorizationFilter
        {
            private readonly string[] _roles;

            public AuthorizationFilter(params string[] roles)
            {
                _roles = roles;
            }
            public void OnAuthorization(AuthorizationFilterContext context)
            {
                var userRole = context.HttpContext.User.Claims.FirstOrDefault(c => c.Type == ClaimNames.Role || c.Type == "Role")?.Value;

                if (userRole == null || !_roles.Any(r => r == userRole))
                {
                    context.Result = new ForbidResult();
                }
            }
        }

    }
   
}
