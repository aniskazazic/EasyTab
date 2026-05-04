using EasyTab.Model.Exceptions;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class LocaleImageService : BaseCRUDService<LocaleImages, LocaleImageSearchObject, LocaleImage, LocaleImageInsertRequest, LocaleImageUpdateRequest>, ILocaleImageService
    {
        public LocaleImageService(_220030Context context, IMapper mapper, IValidator<LocaleImageInsertRequest> insertValidator, IValidator<LocaleImageUpdateRequest> updateValidator) : base(context, mapper, insertValidator, updateValidator)
        {
        }

        protected override IQueryable<LocaleImage> ApplyFilter(IQueryable<LocaleImage> query, LocaleImageSearchObject search)
        {
            query = query.Include(x => x.Locale);

            if (!string.IsNullOrWhiteSpace(search?.FileName))
            {
                query = query.Where(x => x.FileName.Contains(search.FileName));
            }

            if (!string.IsNullOrWhiteSpace(search?.ContentType))
            {
                query = query.Where(x => x.ContentType.Contains(search.ContentType));
            }

            if (search?.LocaleId.HasValue == true)
            {
                query = query.Where(x => x.LocaleId == search.LocaleId);
            }

            return query;
        }

        protected override async Task BeforeInsert(LocaleImage entity, LocaleImageInsertRequest request)
        {
            // Provjera da li lokal postoji
            var localeExists = await Context.Locales.AnyAsync(x => x.Id == request.LocaleId);
            if (!localeExists)
            {
                throw new UserException($"Lokal s ID {request.LocaleId} nije pronađen!");
            }

            await Task.CompletedTask;
        }

        protected override async Task BeforeUpdate(LocaleImage entity, LocaleImageUpdateRequest request)
        {
            // Provjera da li lokal postoji
            var localeExists = await Context.Locales.AnyAsync(x => x.Id == request.LocaleId);
            if (!localeExists)
            {
                throw new UserException($"Lokal s ID {request.LocaleId} nije pronađen!");
            }

            await Task.CompletedTask;
        }

        protected override LocaleImages MapToResponse(LocaleImage entity)
        {
            return base.MapToResponse(entity);
        }
    }
}


