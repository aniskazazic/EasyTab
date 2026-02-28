using EasyTab.Model;
using EasyTab.Model.Requests;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services
{
    public interface IUsersService
    {
        List<Users> GetUsers();
        Users Insert(UserInsertRequest request);
        Users Update(int id, UserUpdateRequest request);
    }
}
