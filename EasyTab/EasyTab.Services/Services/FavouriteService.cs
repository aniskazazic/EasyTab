using EasyTab.Model.Models;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace EasyTab.Services.Services
{
    public class FavouriteService : BaseCRUDService<Favourites, FavouriteSearchObject, Favourite, FavouriteInsertRequest, FavouriteUpdateRequest>, IFavouriteService
    {
        private readonly ILogger<FavouriteService> _logger;

        public FavouriteService(_220030Context context, IMapper mapper, ILogger<FavouriteService> logger, IValidator<FavouriteInsertRequest> insertValidator, IValidator<FavouriteUpdateRequest> updateValidator) : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
        }

        protected override IQueryable<Favourite> ApplyFilter(IQueryable<Favourite> query, FavouriteSearchObject search)
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
            {
                throw new UserException("Lokal je već u favoritima!");
            }

            if (existing != null)
            {
                // Reaktiviraj postojeći
                existing.IsActive = true;
                existing.DateAdded = DateTime.Now;
                Context.SaveChanges();
                _logger.LogInformation("Favourite reactivated. UserId: {UserId}, LocaleId: {LocaleId}", userId, localeId);
                
                var existingResponse = Mapper.Map<Favourites>(existing);
                existingResponse.LocaleId = existing.LocaleId;

                // Učitaj detalje lokala kako bi se odmah bogato prikazali u UI
                var existingLocale = Context.Locales
                    .Include(l => l.Category)
                    .Include(l => l.City)
                    .FirstOrDefault(l => l.Id == localeId);

                if (existingLocale != null)
                {
                    existingResponse.LocaleName = existingLocale.Name;
                    existingResponse.LocaleLogo = existingLocale.Logo;
                    existingResponse.LocaleAddress = existingLocale.Address;
                    existingResponse.LocaleCategoryName = existingLocale.Category?.Name;
                    existingResponse.LocaleCityName = existingLocale.City?.Name;
                }

                return existingResponse;
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

            var newResponse = Mapper.Map<Favourites>(fav);
            newResponse.LocaleId = fav.LocaleId;

            // Učitaj detalje lokala kako bi se odmah bogato prikazali u UI
            var newLocale = Context.Locales
                .Include(l => l.Category)
                .Include(l => l.City)
                .FirstOrDefault(l => l.Id == localeId);

            if (newLocale != null)
            {
                newResponse.LocaleName = newLocale.Name;
                newResponse.LocaleLogo = newLocale.Logo;
                newResponse.LocaleAddress = newLocale.Address;
                newResponse.LocaleCategoryName = newLocale.Category?.Name;
                newResponse.LocaleCityName = newLocale.City?.Name;
            }

            return newResponse;
        }

        public List<Favourites> GetByUser(int userId)
        {
            _logger.LogDebug("Fetching favourites. UserId: {UserId}", userId);
            var favourites = Context.Favourites
                           .Include(f => f.Locale)
                             .ThenInclude(l => l.Category)
                           .Include(f => f.Locale)
                             .ThenInclude(l => l.City)
                           .Where(f => f.UserId == userId && f.IsActive)
                           .ToList();

            var result = favourites.Select(x =>
            {
                var model = Mapper.Map<Favourites>(x);
                model.LocaleId = x.LocaleId;

                model.LocaleLogo = x.Locale?.Logo;
                model.LocaleName = x.Locale?.Name;
                model.LocaleAddress = x.Locale?.Address;
                model.LocaleCategoryName = x.Locale?.Category?.Name;
                model.LocaleCityName = x.Locale?.City?.Name;

                return model;
            }).ToList();

            return result;
        }

        public bool IsFavourited(int userId, int localeId)
        {
            var isFavourited = Context.Favourites
               .Any(f => f.UserId == userId && f.LocaleId == localeId && f.IsActive);
            return isFavourited;
        }

        public void RemoveFromFavourites(int userId, int localeId)
        {
            var fav = Context.Favourites
                      .FirstOrDefault(f => f.UserId == userId && f.LocaleId == localeId && f.IsActive);

            if (fav == null)
            {
                _logger.LogWarning("Cannot remove favourite because it was not found. UserId: {UserId}, LocaleId: {LocaleId}", userId, localeId);
                throw new UserException("Lokal nije u favoritima!");
            }

            fav.IsActive = false;
            Context.SaveChanges();
            _logger.LogWarning("Favourite removed. UserId: {UserId}, LocaleId: {LocaleId}", userId, localeId);
        }
    }
}
