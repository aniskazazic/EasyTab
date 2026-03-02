using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class RoleService : BaseCRUDService<Roles, RoleSearchObject, Role, RoleInsertRequest, RoleUpdateRequest>, IRoleService
    {
        public RoleService(_220030Context context, IMapper mapper) : base(context, mapper) { }

        public override IQueryable<Role> AddFilter(IQueryable<Role> query, RoleSearchObject search)
        {
            query = base.AddFilter(query, search);

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
