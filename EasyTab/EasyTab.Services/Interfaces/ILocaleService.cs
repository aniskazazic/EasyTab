using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Model.Responses;
using EasyTab.Services.BaseServices.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface ILocaleService : ICRUDService<Locales, LocaleSearchObject, LocaleInsertRequest, LocaleUpdateRequest>
    {
        Task<LocaleDeactivationPreviewResponse> GetDeactivationPreviewAsync(int id, CancellationToken cancellationToken = default);
    }
}
