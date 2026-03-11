using EasyTab.Model.Models;
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
    public interface ILocaleImageService : IService<LocaleImages, LocaleImageSearchObject>
    {
        LocaleImages Insert(LocaleImageInsertRequest request);
        void Delete(int id);
        List<LocaleImages> GetByLocale(int localeId);
    }
}
