using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IFavouriteService : ICRUDService<Favourites, FavouriteSearchObject, FavouriteInsertRequest, FavouriteUpdateRequest>
    {
        Favourites AddToFavourites(int localeId);
        void RemoveFromFavourites(int localeId);
        bool IsFavourited(int localeId);
        List<Favourites> GetByUser();
    }
}
