using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace EasyTab.Services.Services
{
    public class LocaleService : BaseCRUDService<Locales, LocaleSearchObject, Locale, LocaleInsertRequest, LocaleUpdateRequest>, ILocaleService
    {

        private readonly IWebHostEnvironment _wh;
        private readonly string _baseUrl;

        public LocaleService(_220030Context context, IMapper mapper, IWebHostEnvironment wh, IConfiguration config) : base(context, mapper)
        {
            _wh = wh;
            _baseUrl = config["APP_BASE_URL"] ?? "http://localhost:5241";
        }

        protected override IQueryable<Locale> ApplyFilter(IQueryable<Locale> query, LocaleSearchObject search)
        {
            query = query.Include(x => x.City).ThenInclude(x => x.Country)
                         .Include(x => x.Category)
                         .Include(x => x.Owner);

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

            if (search?.IsDeleted == true)
                query = query.Where(x => x.IsDeleted == search.IsDeleted);

            if (search?.OwnerId.HasValue == true)
                query = query.Where(x => x.OwnerId == search.OwnerId);

            return query;
        }

        private static string ExtractBase64(string logo)
        {
            if (logo.Contains(','))
                return logo.Split(',')[1];

            var idx = logo.IndexOf("base64", StringComparison.OrdinalIgnoreCase);
            if (idx >= 0)
            {
                idx += 6; 
                while (idx < logo.Length
                       && !char.IsLetterOrDigit(logo[idx])
                       && logo[idx] != '+'
                       && logo[idx] != '/')
                    idx++;
                return logo.Substring(idx);
            }

            return logo;
        }

        private string SaveLogoToDisk(string logoRaw)
        {
            string folderPath = Path.Combine(_wh.WebRootPath, "ImageFolder", "LocaleLogo");
            if (!Directory.Exists(folderPath))
                Directory.CreateDirectory(folderPath);

            var base64 = ExtractBase64(logoRaw);
            var fileName = $"{Guid.NewGuid()}.png";
            var savePath = Path.Combine(folderPath, fileName);
            File.WriteAllBytes(savePath, Convert.FromBase64String(base64));
            return fileName;
        }

        protected override async Task BeforeInsert(Locale entity, LocaleInsertRequest request)
        {
            entity.Logo = string.IsNullOrWhiteSpace(request.Logo)
                ? null
                : Path.GetFileName(request.Logo);
            await Task.CompletedTask;
        }

        protected override Locales MapToResponse(Locale entity)
        {
            var model = base.MapToResponse(entity);

            model.CountryName = entity.City?.Country?.Name;
            model.OwnerName = entity.Owner != null
                ? $"{entity.Owner.FirstName} {entity.Owner.LastName}"
                : null;

            if (!string.IsNullOrEmpty(entity.Logo))
                model.Logo = $"{_baseUrl}/ImageFolder/LocaleLogo/{entity.Logo}";

            return model;
        }

        protected override async Task BeforeUpdate(Locale entity, LocaleUpdateRequest request)
        {
            if (!string.IsNullOrWhiteSpace(request.Logo))
                entity.Logo = Path.GetFileName(request.Logo);
            await Task.CompletedTask;
        }
    }
}