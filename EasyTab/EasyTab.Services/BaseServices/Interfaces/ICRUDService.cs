using EasyTab.Model.SearchObject;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.BaseServices.Interfaces
{
    public interface ICRUDService<TModel, TSearch, TInsert, TUpdate> : IService<TModel, TSearch> where TModel : class where TSearch : BaseSearchObject 
    {
        TModel Insert(TInsert request);
        TUpdate Update(int id, TUpdate request);
        void Delete(int id);
    }
}
