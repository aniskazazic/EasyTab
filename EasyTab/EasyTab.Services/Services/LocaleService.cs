using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
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
    public class LocaleService : BaseCRUDService<Locales, LocaleSearchObject, Locale, LocaleInsertRequest, LocaleUpdateRequest>, ILocaleService
    {
        
        private readonly IWebHostEnvironment _wh;
        public LocaleService(_220030Context context, IMapper mapper, IWebHostEnvironment wh) : base(context, mapper)
        {
            _wh = wh;
        }

        protected override IQueryable<Locale> ApplyFilter(IQueryable<Locale> query, LocaleSearchObject search)
        {
            query = query.Include(x => x.City).ThenInclude(x=> x.Country)
                                   .Include(x => x.Category)
                                   .Include(x => x.Owner);

            query = query.Where(x => !x.IsDeleted);

            if (!string.IsNullOrEmpty(search?.Name))
                query = query.Where(x => x.Name.Contains(search.Name));

            if (search?.CityId.HasValue == true)
                query = query.Where(x => x.CityId == search.CityId);

            if (search?.CategoryId.HasValue == true)
                query = query.Where(x => x.CategoryId == search.CategoryId);

            if (search?.IsDeleted.HasValue == true)
                query = query.Where(x => x.IsDeleted == search.IsDeleted);

            if (search?.CountryId.HasValue == true)
                query = query.Where(x => x.City.CountryId == search.CountryId);

            return query;
        }

        protected override async Task BeforeInsert(Locale entity, LocaleInsertRequest request)
        {
            if (!string.IsNullOrWhiteSpace(request.Logo) && request.Logo.Contains("base64"))
            {
                string folderPath = Path.Combine(_wh.WebRootPath, "ImageFolder", "LocaleLogo");
                if (!Directory.Exists(folderPath))
                    Directory.CreateDirectory(folderPath);

                var base64 = request.Logo.Split(',')[1];
                var fileName = $"{Guid.NewGuid()}.png";
                var savePath = Path.Combine(folderPath, fileName);
                var bytes = Convert.FromBase64String(base64);
                File.WriteAllBytes(savePath, bytes);

                entity.Logo = fileName;
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

            return model;
        }

        protected override async Task BeforeUpdate(Locale entity, LocaleUpdateRequest request)
        {
            if (!string.IsNullOrWhiteSpace(request.Logo) && request.Logo.Contains("base64"))
            {
                string folderPath = Path.Combine(_wh.WebRootPath, "ImageFolder", "LocaleLogo");
                if (!Directory.Exists(folderPath))
                    Directory.CreateDirectory(folderPath);

                var base64 = request.Logo.Split(',')[1];
                var fileName = $"{Guid.NewGuid()}.png";
                var savePath = Path.Combine(folderPath, fileName);
                File.WriteAllBytes(savePath, Convert.FromBase64String(base64));
                entity.Logo = fileName;
            }

            entity.IsDeleted = false;
            await Task.CompletedTask;
        }
    }
}
