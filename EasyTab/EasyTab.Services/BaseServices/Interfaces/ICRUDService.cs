using EasyTab.Model.SearchObject;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.BaseServices.Interfaces
{
    public interface ICRUDService<TModel, TSearch, TInsert, TUpdate> : IService<TModel, TSearch> where TModel : class where TSearch : BaseSearchObject where TInsert : class where TUpdate : class
    {
        Task<TModel> CreateAsync(TInsert request);
        Task<TModel?> UpdateAsync(int id, TUpdate request);
        Task<bool> DeleteAsync(int id);
    }
}
