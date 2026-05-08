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
            var entity = Mapper.Map<Locale>(request);
            Context.Locales.Add(entity);
            await Context.SaveChangesAsync();
            var response = Mapper.Map<Locales>(entity);
            return response;
        }

        public override async Task<Locales?> UpdateAsync(int id, LocaleUpdateRequest request)
        {
            _logger.LogInformation("Updating locale. LocaleId: {LocaleId}, LocaleName: {LocaleName}", id, request.Name);
            return await base.UpdateAsync(id, request);
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

        protected override async Task BeforeUpdate(Locale entity, LocaleUpdateRequest request)
        {
            if (request.Logo == "")
                entity.Logo = null;
            else if (!string.IsNullOrWhiteSpace(request.Logo))
                entity.Logo = request.Logo;

            // Obrada slika
            if (request.Images != null && request.Images.Any())
            {

                // Dodaj nove slike
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

            await Task.CompletedTask;
        }
    }
}