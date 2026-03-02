using EasyTab.Model;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IUserService : ICRUDService<Users, UserSearchObject, UserInsertRequest, UserUpdateRequest>
    {
        Users Login(string username, string password);
    }
}
