using EasyTab.Model;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace EasyTab.Services.Services
{
    public class LocaleService : BaseCRUDService<Locales, LocaleSearchObject, Locale, LocaleInsertRequest, LocaleUpdateRequest>, ILocaleService
    {

        private readonly IWebHostEnvironment _wh;
        private readonly ILogger<LocaleService> _logger;

        public LocaleService(_220030Context context, IMapper mapper, IWebHostEnvironment wh, ILogger<LocaleService> logger, IValidator<LocaleInsertRequest> insertValidator, IValidator<LocaleUpdateRequest> updateValidator) : base(context, mapper, insertValidator, updateValidator)
        {
            _wh = wh;
            _logger = logger;
        }

        public override async Task<Locales> CreateAsync(LocaleInsertRequest request)
        {
            _logger.LogInformation("Creating locale. LocaleName: {LocaleName}", request.Name);

            // Validacija CityId
            var cityExists = await Context.Cities.AnyAsync(c => c.Id == request.CityId);
            if (!cityExists)
            {
                throw new KeyNotFoundException($"Grad sa ID {request.CityId} ne postoji.");
            }

            // Validacija CategoryId
            var categoryExists = await Context.Categories.AnyAsync(c => c.Id == request.CategoryId);
            if (!categoryExists)
            {
                throw new KeyNotFoundException($"Kategorija sa ID {request.CategoryId} ne postoji.");
            }

            var entity = Mapper.Map<Locale>(request);
            Context.Locales.Add(entity);
            await Context.SaveChangesAsync();
            var response = Mapper.Map<Locales>(entity);
            return response;
        }

        public override async Task<Locales?> UpdateAsync(int id, LocaleUpdateRequest request)
        {
            await _updateValidator.ValidateAndThrowAsync(request);

            _logger.LogInformation("Updating locale. LocaleId: {LocaleId}, LocaleName: {LocaleName}", id, request.Name);

            var entity = await Context.Locales.FindAsync(id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"Lokala sa ID {id} ne postoji.");
            }

            await BeforeUpdate(entity, request);
            // Čuva sve izmene
            await Context.SaveChangesAsync();

            // Vraća response
            return MapToResponse(entity);
        }

        public override async Task<Locales?> GetByIdAsync(int id)
        {
            var entity = await Context.Locales
                .Include(x => x.City)
                .Include(x => x.Category)
                .Include(x => x.Owner)
                .Include(x => x.LocaleImages)
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                return null;

            var model = Mapper.Map<Locales>(entity);
            model.CityName = entity.City?.Name;
            model.CategoryName = entity.Category?.Name;
            model.OwnerName = entity.Owner != null ? $"{entity.Owner.FirstName} {entity.Owner.LastName}" : null;
            model.AverageRating = await GetAverageRatingForLocaleAsync(entity.Id);

            return model;
        }

        public override async Task<PagedResult<Locales>> GetAsync(LocaleSearchObject search)
        {
            var result = await base.GetAsync(search);
            if (result.Items == null || result.Items.Count == 0)
                return result;

            await ApplyAverageRatingsAsync(result.Items);
            return result;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            _logger.LogWarning("Deleting locale. LocaleId: {LocaleId}", id);
            return await base.DeleteAsync(id);
        }

        protected override IQueryable<Locale> ApplyFilter(IQueryable<Locale> query, LocaleSearchObject search)
        {
            query = query.Include(x => x.City).ThenInclude(x => x.Country)
                         .Include(x => x.Category)
                         .Include(x => x.Owner)
                         .Include(x => x.LocaleImages);

            // Default: prikaži samo aktivne
            // Ako IsDeleted == true (checkbox čekiran) — prikaži SVE (aktivne + obrisane)
            if (search?.IsDeleted != true)
                query = query.Where(x => !x.IsDeleted);

            if (!string.IsNullOrEmpty(search?.Name))
                query = query.Where(x => x.Name.Contains(search.Name));

            if (search?.CityId.HasValue == true)
                query = query.Where(x => x.CityId == search.CityId);

            if (search?.CategoryId.HasValue == true)
                query = query.Where(x => x.CategoryId == search.CategoryId);

            if (search?.CountryId.HasValue == true)
                query = query.Where(x => x.City.CountryId == search.CountryId);

            if (search?.OwnerId.HasValue == true)
                query = query.Where(x => x.OwnerId == search.OwnerId);

            return query;
        }

        protected override async Task BeforeInsert(Locale entity, LocaleInsertRequest request)
        {
            entity.Logo = string.IsNullOrWhiteSpace(request.Logo) ? null : request.Logo;

            // Obrada slika
            if (request.Images != null && request.Images.Any())
            {
                foreach (var imageRequest in request.Images)
                {
                    

                    var localeImage = new LocaleImage
                    {
                        FileName = imageRequest.FileName,
                        ContentType = imageRequest.ContentType,
                        Base64Content = imageRequest.Base64Content,
                        LocaleId = entity.Id,
                        CreatedAt = DateTime.UtcNow
                    };

                    entity.LocaleImages.Add(localeImage);
                }
            }

            await Task.CompletedTask;
        }

        protected override Locales MapToResponse(Locale entity)
        {
            var model = base.MapToResponse(entity);

            model.CityName = entity.City?.Name;
            model.CategoryName = entity.Category?.Name;
            model.CountryName = entity.City?.Country?.Name;
            model.OwnerName = entity.Owner != null
                ? $"{entity.Owner.FirstName} {entity.Owner.LastName}"
                : null;

            model.Logo = entity.Logo;

            // Mapiranje slika
            if (entity.LocaleImages != null && entity.LocaleImages.Any())
            {
                model.Images = entity.LocaleImages.Select(img => new LocaleImages
                {
                    Id = img.Id,
                    FileName = img.FileName,
                    ContentType = img.ContentType,
                    Base64Content = img.Base64Content,
                    CreatedAt = img.CreatedAt,
                    LocaleId = img.LocaleId
                }).ToList();
            }
            else
            {
                model.Images = new List<LocaleImages>();
            }

            return model;
        }

        private async Task ApplyAverageRatingsAsync(IList<Locales> locales)
        {
            var localeIds = locales.Select(x => x.Id).ToList();
            var averages = await Context.Reviews
                .Where(r => localeIds.Contains(r.LocaleId) && !r.IsDeleted)
                .GroupBy(r => r.LocaleId)
                .Select(g => new { LocaleId = g.Key, Average = g.Average(r => (double)r.Rating) })
                .ToDictionaryAsync(x => x.LocaleId, x => x.Average);

            foreach (var locale in locales)
            {
                locale.AverageRating = averages.TryGetValue(locale.Id, out var average) ? average : 0;
            }
        }

        private async Task<double> GetAverageRatingForLocaleAsync(int localeId)
        {
            var reviews = Context.Reviews
                .Where(r => r.LocaleId == localeId && !r.IsDeleted);

            if (!await reviews.AnyAsync())
                return 0;

            return await reviews.AverageAsync(r => (double)r.Rating);
        }

        protected override async Task BeforeUpdate(Locale entity, LocaleUpdateRequest request)
        {

            var oldCityId = entity.CityId;
            var oldCategoryId = entity.CategoryId;
            var oldName = entity.Name;
            var oldAddress = entity.Address;
            var oldPhoneNumber = entity.PhoneNumber;
            var oldLogo = entity.Logo;
            var oldStartOfWorkingHours = entity.StartOfWorkingHours;
            var oldEndOfWorkingHours = entity.EndOfWorkingHours;
            var oldLengthOfReservation = entity.LengthOfReservation;

            if (!string.IsNullOrWhiteSpace(request.Name))
                entity.Name = request.Name;

            if (!string.IsNullOrWhiteSpace(request.Address))
                entity.Address = request.Address;

            if (!string.IsNullOrWhiteSpace(request.PhoneNumber))
                entity.PhoneNumber = request.PhoneNumber;

            if (request.CityId.HasValue)
                entity.CityId = request.CityId.Value;

            if (request.CategoryId.HasValue)
                entity.CategoryId = request.CategoryId.Value;

            if (request.StartOfWorkingHours.HasValue)
                entity.StartOfWorkingHours = request.StartOfWorkingHours.Value;

            if (request.EndOfWorkingHours.HasValue)
                entity.EndOfWorkingHours = request.EndOfWorkingHours.Value;

            if (request.LengthOfReservation.HasValue)
                entity.LengthOfReservation = request.LengthOfReservation.Value;

            if (request.Logo == "")
                entity.Logo = null;
            else if (!string.IsNullOrWhiteSpace(request.Logo))
                entity.Logo = request.Logo;

            if (request.IsDeleted.HasValue)
                entity.IsDeleted = request.IsDeleted.Value;

            var cityIdToCheck = request.CityId ?? oldCityId;
            var cityExists = await Context.Cities.AnyAsync(c => c.Id == cityIdToCheck);
            if (!cityExists)
            {
                throw new KeyNotFoundException($"Grad sa ID {cityIdToCheck} ne postoji. Molim odaberite validnu lokaciju.");
            }

            var categoryIdToCheck = request.CategoryId ?? oldCategoryId;
            var categoryExists = await Context.Categories.AnyAsync(c => c.Id == categoryIdToCheck);
            if (!categoryExists)
            {
                throw new KeyNotFoundException($"Kategorija sa ID {categoryIdToCheck} ne postoji. Molim odaberite validnu kategoriju.");
            }

            if (request.Images != null && request.Images.Any())
            {
                foreach (var imageRequest in request.Images)
                {
                    var localeImage = new LocaleImage
                    {
                        FileName = imageRequest.FileName,
                        ContentType = imageRequest.ContentType,
                        Base64Content = imageRequest.Base64Content,
                        LocaleId = entity.Id,
                        CreatedAt = DateTime.UtcNow
                    };

                    Context.LocaleImages.Add(localeImage);
                }
            }

            entity.DeletedAt = null;

            await Task.CompletedTask;
        }
    }
}