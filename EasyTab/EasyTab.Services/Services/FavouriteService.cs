using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class FavouriteService : BaseCRUDService<Favourites, FavouriteSearchObject, Favourite, FavouriteInsertRequest, FavouriteUpdateRequest>, IFavouriteService
    {
        private readonly IWebHostEnvironment _wh;

        public FavouriteService(_220030Context context, IMapper mapper, IWebHostEnvironment wh) : base(context, mapper)
        {
            _wh = wh;
        }

        public override IQueryable<Favourite> AddFilter(IQueryable<Favourite> query, FavouriteSearchObject search)
        {
            query = query.Include(x => x.Locale)
                        .Include(x => x.User);

            if (search?.UserId.HasValue == true)
                query = query.Where(x => x.UserId == search.UserId);

            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.LocaleId == search.LocaleId);

            return query;
        }

        public Favourites AddToFavourites(int userId, int localeId)
        {
            var existing = Context.Favourites
                            .FirstOrDefault(f => f.UserId == userId && f.LocaleId == localeId);

            if (existing != null && existing.IsActive)
                throw new Exception("Lokal je već u favoritima!");

            if (existing != null)
            {
                // Reaktiviraj postojeći
                existing.IsActive = true;
                existing.DateAdded = DateTime.Now;
                Context.SaveChanges();
                return Mapper.Map<Favourites>(existing);
            }

            // Novi favorit
            var fav = new Favourite
            {
                UserId = userId,
                LocaleId = localeId,
                DateAdded = DateTime.Now,
                IsActive = true
            };

            Context.Favourites.Add(fav);
            Context.SaveChanges();

            return Mapper.Map<Favourites>(fav);
        }

        public List<Favourites> GetByUser(int userId)
        {
            var favourites = Context.Favourites
                           .Include(f => f.Locale)
                           .Where(f => f.UserId == userId && f.IsActive)
                           .ToList();

            var result = favourites.Select(x =>
            {
                var model = Mapper.Map<Favourites>(x);

                // Učitaj logo kao base64
                if (!string.IsNullOrEmpty(x.Locale.Logo))
                {
                    string logoPath = Path.Combine(_wh.WebRootPath, "ImageFolder", "LocaleLogo", x.Locale.Logo);
                    if (File.Exists(logoPath))
                    {
                        byte[] imageBytes = File.ReadAllBytes(logoPath);
                        model.LocaleLogo = $"data:image/png;base64,{Convert.ToBase64String(imageBytes)}";
                    }
                }

                return model;
            }).ToList();

            return result;
        }

        public bool IsFavourited(int userId, int localeId)
        {
            return Context.Favourites
               .Any(f => f.UserId == userId && f.LocaleId == localeId && f.IsActive);
        }

        public void RemoveFromFavourites(int userId, int localeId)
        {
            var fav = Context.Favourites
                      .FirstOrDefault(f => f.UserId == userId && f.LocaleId == localeId && f.IsActive);

            if (fav == null)
                throw new Exception("Lokal nije u favoritima!");

            fav.IsActive = false;
            Context.SaveChanges();
        }
    }
}
