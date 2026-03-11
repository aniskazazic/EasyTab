using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Hosting;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class LocaleImageService : BaseService<LocaleImages, LocaleImageSearchObject, LocaleImage>, ILocaleImageService
    {
        private readonly IWebHostEnvironment _wh;

        public LocaleImageService(_220030Context context, IMapper mapper, IWebHostEnvironment wh) : base(context, mapper)
        {
            _wh = wh;
        }

        protected override IQueryable<LocaleImage> ApplyFilter(IQueryable<LocaleImage> query, LocaleImageSearchObject search)
        {
            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.LocaleId == search.LocaleId);

            return query;
        }

        public void Delete(int id)
        {
            var image = Context.LocaleImages.Find(id);
            if (image == null)
                throw new Exception("Slika nije pronađena!");

            // Fizički obriši fajl
            string filePath = Path.Combine(_wh.WebRootPath, "ImageFolder", "LocaleImages", image.ImageUrl);
            if (File.Exists(filePath))
                File.Delete(filePath);

            Context.LocaleImages.Remove(image);
            Context.SaveChanges();
        }

        public List<LocaleImages> GetByLocale(int localeId)
        {
            var images = Context.LocaleImages
                .Where(x => x.LocaleId == localeId)
                .ToList();

            return images.Select(image =>
            {
                var model = Mapper.Map<LocaleImages>(image);

                // Učitaj sliku kao base64
                string imagePath = Path.Combine(_wh.WebRootPath, "ImageFolder", "LocaleImages", image.ImageUrl);
                if (File.Exists(imagePath))
                {
                    byte[] bytes = File.ReadAllBytes(imagePath);
                    var ext = Path.GetExtension(imagePath).TrimStart('.');
                    model.ImageBase64 = $"data:image/{ext};base64,{Convert.ToBase64String(bytes)}";
                    model.ContentType = GetContentType(imagePath);
                }

                return model;
            }).ToList();
        }

        public LocaleImages Insert(LocaleImageInsertRequest request)
        {
            var locale = Context.Locales.Find(request.LocaleId);
            if (locale == null)
                throw new Exception("Lokal nije pronađen!");

            string folderPath = Path.Combine(_wh.WebRootPath, "ImageFolder", "LocaleImages");
            if (!Directory.Exists(folderPath))
                Directory.CreateDirectory(folderPath);

            var base64 = request.ImageBase64.Split(',')[1];
            var ext = GetImageType(request.ImageBase64);
            var fileName = $"{Guid.NewGuid()}.{ext}";
            var savePath = Path.Combine(folderPath, fileName);

            File.WriteAllBytes(savePath, Convert.FromBase64String(base64));

            var entity = new LocaleImage
            {
                LocaleId = request.LocaleId,
                ImageUrl = fileName
            };

            Context.LocaleImages.Add(entity);
            Context.SaveChanges();

            return Mapper.Map<LocaleImages>(entity);
        }

        private string GetImageType(string base64String)
        {
            var match = System.Text.RegularExpressions.Regex.Match(
                base64String, @"^data:image/(?<type>[a-zA-Z]+);base64,");
            return match.Success ? match.Groups["type"].Value.ToLower() : "png";
        }

        private string GetContentType(string path)
        {
            var ext = Path.GetExtension(path).ToLowerInvariant();
            return ext switch
            {
                ".jpg" or ".jpeg" => "image/jpeg",
                ".png" => "image/png",
                ".gif" => "image/gif",
                _ => "application/octet-stream"
            };
        }

    }
}
