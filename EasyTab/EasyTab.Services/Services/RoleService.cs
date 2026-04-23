using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class RoleService : BaseCRUDService<Roles, RoleSearchObject, Role, RoleInsertRequest, RoleUpdateRequest>, IRoleService
    {
        private readonly ILogger<RoleService> _logger;

        public RoleService(_220030Context context, IMapper mapper, ILogger<RoleService> logger, IValidator<RoleInsertRequest> insertValidator, IValidator<RoleUpdateRequest> updateValidator) 
            : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
        }

        public override async Task<Roles> CreateAsync(RoleInsertRequest request)
        {
            _logger.LogInformation("Creating role. RoleName: {RoleName}", request.Name);
            return await base.CreateAsync(request);
        }

        public override async Task<Roles?> UpdateAsync(int id, RoleUpdateRequest request)
        {
            _logger.LogInformation("Updating role. RoleId: {RoleId}, RoleName: {RoleName}", id, request.Name);
            return await base.UpdateAsync(id, request);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            _logger.LogWarning("Deleting role. RoleId: {RoleId}", id);
            return await base.DeleteAsync(id);
        }

        protected override IQueryable<Role> ApplyFilter(IQueryable<Role> query, RoleSearchObject search)
        {
            query = base.ApplyFilter(query, search);

            if (!string.IsNullOrWhiteSpace(search.NameGTE))
            {
                query = query.Where(x => x.Name.StartsWith(search.NameGTE));
            }

            if (search?.IsDeleted == true)
            {
                query = query.Where(x => x.IsDeleted == search.IsDeleted);
            }
            return query;
        }
    }
}
