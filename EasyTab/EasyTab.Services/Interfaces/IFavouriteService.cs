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
        Task<Favourites> AddToFavouritesAsync(int localeId);
        Task RemoveFromFavouritesAsync(int localeId);
        Task<bool> IsFavouritedAsync(int localeId);
        Task<List<Favourites>> GetByUserAsync();
    }
}
