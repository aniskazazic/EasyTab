using EasyTab.Model;
using EasyTab.Model.SearchObject;
using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.BaseServices.Interfaces
{
    public interface IService<TModel, TSearch> where TSearch : BaseSearchObject
    {
        Task<PagedResult<TModel>> GetAsync(TSearch search);
        Task<TModel?> GetByIdAsync(int id);
    }
}
