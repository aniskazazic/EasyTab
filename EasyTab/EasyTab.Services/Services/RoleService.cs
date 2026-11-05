using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model;
using EasyTab.Model.Exceptions;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
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
            request.Name = request.Name?.Trim() ?? string.Empty;
            _logger.LogInformation("Creating role. RoleName: {RoleName}", request.Name);
            return await base.CreateAsync(request);
        }

        public override async Task<Roles?> UpdateAsync(int id, RoleUpdateRequest request)
        {
            await EnsureMutableAsync(id, "uređivati");
            request.Name = request.Name?.Trim() ?? string.Empty;
            _logger.LogInformation("Updating role. RoleId: {RoleId}, RoleName: {RoleName}", id, request.Name);
            return await base.UpdateAsync(id, request);
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            await EnsureMutableAsync(id, "obrisati");
            _logger.LogWarning("Deleting role. RoleId: {RoleId}", id);
            return await base.DeleteAsync(id);
        }

        private async Task EnsureMutableAsync(int id, string action)
        {
            var role = await _context.Roles.SingleOrDefaultAsync(role => role.Id == id && !role.IsDeleted)
                ?? throw new NotFoundException("Uloga nije pronađena.");

            var systemRoles = new[] { RoleNames.Admin, RoleNames.Vlasnik, RoleNames.Radnik, RoleNames.Korisnik };
            if (systemRoles.Contains(role.Name.Trim(), StringComparer.OrdinalIgnoreCase))
                throw new UserException($"Sistemsku ulogu nije moguće {action}.");

            if (await _context.UserRoles.AnyAsync(userRole => userRole.RoleId == id))
                throw new UserException($"Ulogu nije moguće {action} jer je dodijeljena korisniku.");
        }

        protected override void MapUpdateToEntity(Role entity, RoleUpdateRequest request)
        {
            entity.Name = request.Name;
            entity.Description = request.Description;
        }

        protected override IQueryable<Role> ApplyFilter(IQueryable<Role> query, RoleSearchObject? search)
        {
            query = base.ApplyFilter(query, search);

            var name = search?.NameGTE?.Trim();
            if (!string.IsNullOrWhiteSpace(name))
            {
                query = query.Where(x => x.Name.StartsWith(name));
            }

            var isDeleted = search?.IsDeleted ?? false;
            return query.Where(x => x.IsDeleted == isDeleted);
        }
    }
}
