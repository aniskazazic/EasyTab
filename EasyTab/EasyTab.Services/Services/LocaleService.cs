using EasyTab.Model;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Model.Responses;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.Validators;
using EasyTab.Services.ReservationStateMachine;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.AspNetCore.Http;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;


namespace EasyTab.Services.Services
{
    public class LocaleService : BaseCRUDService<Locales, LocaleSearchObject, Locale, LocaleInsertRequest, LocaleUpdateRequest>, ILocaleService
    {

        private readonly ILogger<LocaleService> _logger;
        private readonly ILocaleAccessService _localeAccessService;
        private readonly ICurrentUserService _currentUser;
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private const string DeactivationReason = "Lokal je deaktiviran";

        public LocaleService(_220030Context context, IMapper mapper, ILogger<LocaleService> logger, IValidator<LocaleInsertRequest> insertValidator, IValidator<LocaleUpdateRequest> updateValidator, ILocaleAccessService localeAccessService, ICurrentUserService currentUser, IServiceScopeFactory scopeFactory, IHttpContextAccessor httpContextAccessor) : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
            _localeAccessService = localeAccessService;
            _currentUser = currentUser;
            _scopeFactory = scopeFactory;
            _httpContextAccessor = httpContextAccessor;
        }

        public override async Task<Locales> CreateAsync(LocaleInsertRequest request)
        {
            if (_currentUser.Role == RoleNames.Vlasnik)
                request.OwnerId = _currentUser.UserId;
            await _insertValidator.ValidateForUserAsync(request);
            ImageContentValidator.ValidateOptionalImage(request.Logo, nameof(request.Logo));
            ValidateGalleryImages(request.Images);

            _logger.LogInformation("Creating locale. LocaleName: {LocaleName}", request.Name);

            // Validacija CityId
            var cityExists = await Context.Cities.AnyAsync(c => c.Id == request.CityId);
            if (!cityExists)
            {
                throw new UserException("Odabrani grad ne postoji.");
            }

            // Validacija CategoryId
            var categoryExists = await Context.Categories.AnyAsync(c => c.Id == request.CategoryId);
            if (!categoryExists)
            {
                throw new UserException("Odabrana kategorija ne postoji.");
            }

            if (!await Context.Users.AnyAsync(user => user.Id == request.OwnerId && !user.IsDeleted))
                throw new UserException("Odabrani vlasnik ne postoji.");

            var entity = Mapper.Map<Locale>(request);
            await BeforeInsert(entity, request);
            Context.Locales.Add(entity);
            await Context.SaveChangesAsync();
            return MapToResponse(entity);
        }

        public override async Task<Locales?> UpdateAsync(int id, LocaleUpdateRequest request)
        {
            if (request.IsDeleted.HasValue)
                EnsureAdmin();

            await _updateValidator.ValidateAndThrowAsync(request);
            ImageContentValidator.ValidateOptionalImage(request.Logo, nameof(request.Logo));
            ValidateGalleryImages(request.Images);

            _logger.LogInformation("Updating locale. LocaleId: {LocaleId}, LocaleName: {LocaleName}", id, request.Name);

            var entity = await Context.Locales.FindAsync(id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"Lokala sa ID {id} ne postoji.");
            }

            await _localeAccessService.EnsureCanManageLocaleAsOwnerAsync(id);
            await ValidateUpdateReferencesAsync(entity, request);

            if (request.IsDeleted == true)
            {
                await DeactivateAsync(id, request);
                return MapToResponse(entity);
            }

            await using var transaction = await Context.Database.BeginTransactionAsync(CancellationToken.None);
            await ReservationOperationLock.LocaleAsync(Context, id);
            await Context.Entry(entity).ReloadAsync(CancellationToken.None);
            await BeforeUpdate(entity, request);
            // Čuva sve izmene
            await Context.SaveChangesAsync();
            await transaction.CommitAsync(CancellationToken.None);

            // Vraća response
            return MapToResponse(entity);
        }

        public override async Task<Locales?> GetByIdAsync(int id)
        {
            var entity = await Context.Locales
                .Include(x => x.City)
                    .ThenInclude(x => x.Country)
                .Include(x => x.Category)
                .Include(x => x.Owner)
                .Include(x => x.LocaleImages)
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                return null;

            var model = MapToResponse(entity);
            model.AverageRating = await GetAverageRatingForLocaleAsync(entity.Id);

            return model;
        }

        public override async Task<PagedResult<Locales>> GetAsync(LocaleSearchObject search)
        {
            var result = await base.GetAsync(search);
            if (result.Items == null || result.Items.Count == 0)
                return result;

            foreach (var locale in result.Items)
                locale.Images = null;

            await ApplyAverageRatingsAsync(result.Items);
            return result;
        }

        private static void ValidateGalleryImages(
            IReadOnlyList<LocaleImageInsertRequest>? images)
        {
            if (images == null)
                return;

            for (var index = 0; index < images.Count; index++)
            {
                var image = images[index];
                if (image == null)
                {
                    ImageContentValidator.ValidateRequiredImage(
                        null,
                        null,
                        $"Images[{index}].Base64Content",
                        null);
                    continue;
                }

                ImageContentValidator.ValidateRequiredImage(
                    image.Base64Content,
                    image.ContentType,
                    $"Images[{index}].Base64Content",
                    image.FileName);
            }
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            EnsureAdmin();
            return await DeactivateAsync(id);
        }

        public async Task<LocaleDeactivationPreviewResponse> GetDeactivationPreviewAsync(int id, CancellationToken cancellationToken = default)
        {
            EnsureAdmin();
            if (!await Context.Locales.AnyAsync(locale => locale.Id == id, cancellationToken))
                throw new NotFoundException("Lokal nije pronađen.");
            return new LocaleDeactivationPreviewResponse
            {
                FutureReservationsCount = (await GetFutureReservationIdsAsync(id, cancellationToken)).Count
            };
        }

        private void EnsureAdmin()
        {
            if (!_currentUser.IsAdmin)
                throw new ForbiddenException("Samo administrator može deaktivirati ili reaktivirati lokal.");
        }

        private async Task<List<int>> GetFutureReservationIdsAsync(int localeId, CancellationToken cancellationToken)
        {
            var candidates = await Context.Reservations.AsNoTracking()
                .Where(reservation => reservation.Table.LocaleId == localeId &&
                    (reservation.ReservationState == PendingReservationState.StateName ||
                     reservation.ReservationState == ConfirmedReservationState.StateName))
                .OrderBy(reservation => reservation.Id)
                .Select(reservation => new { reservation.Id, reservation.ReservationDate, reservation.StartTime })
                .ToListAsync(cancellationToken);
            var now = LocalClock.Now;
            // Project only identifiers and time fields; the start rule is shared with slot selection.
            return candidates.Where(reservation => ReservationTime.GetStart(reservation.ReservationDate, reservation.StartTime) > now)
                .Select(reservation => reservation.Id).ToList();
        }

        private async Task<bool> DeactivateAsync(int id, LocaleUpdateRequest? request = null)
        {
            EnsureAdmin();
            if (!await Context.Locales.AnyAsync(locale => locale.Id == id))
                throw new NotFoundException("Lokal nije pronađen.");

            var cancellationToken = _httpContextAccessor.HttpContext?.RequestAborted ?? CancellationToken.None;
            var cancelledCount = 0;
            void CheckRequest()
            {
                if (cancellationToken.IsCancellationRequested)
                    throw new UserException($"Deaktivacija je prekinuta. Lokal je i dalje aktivan. Već otkazano rezervacija: {cancelledCount}. Ponovite postupak za preostale rezervacije.");
            }

            while (true)
            {
                CheckRequest();
                var ids = await GetFutureReservationIdsAsync(id, CancellationToken.None);
                foreach (var reservationId in ids)
                {
                    CheckRequest();
                    try
                    {
                        // One independent, non-cancellable unit: refund, reservation, notifications, email.
                        await using var scope = _scopeFactory.CreateAsyncScope();
                        var db = scope.ServiceProvider.GetRequiredService<_220030Context>();
                        var stateName = await db.Reservations.AsNoTracking()
                            .Where(reservation => reservation.Id == reservationId)
                            .Select(reservation => reservation.ReservationState).SingleAsync(CancellationToken.None);
                        BaseReservationState? state = stateName switch
                        {
                            PendingReservationState.StateName => scope.ServiceProvider.GetRequiredService<PendingReservationState>(),
                            ConfirmedReservationState.StateName => scope.ServiceProvider.GetRequiredService<ConfirmedReservationState>(),
                            _ => null
                        };
                        if (state == null)
                            continue;
                        try
                        {
                            await state.CancelBySystemAsync(reservationId, DeactivationReason, futureOnly: true);
                        }
                        finally
                        {
                            if (state.CancellationCommitted)
                                cancelledCount++;
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Locale deactivation stopped at reservation {ReservationId}. LocaleId: {LocaleId}, CancelledCount: {CancelledCount}", reservationId, id, cancelledCount);
                        var reason = ex is UserException ? ex.Message : "Povrat uplate ili snimanje rezervacije nije uspjelo. Pokušajte ponovo.";
                        throw new UserException($"Lokal nije deaktiviran. Već otkazano rezervacija: {cancelledCount}. {reason}");
                    }
                }

                CheckRequest();
                try
                {
                    await using var transaction = await Context.Database.BeginTransactionAsync(CancellationToken.None);
                    await ReservationOperationLock.LocaleAsync(Context, id);
                    await ReservationOperationLock.LockTablesAsync(Context, id);
                    // Checkout uses the same locks, so no reservation can slip past this final check.
                    if ((await GetFutureReservationIdsAsync(id, CancellationToken.None)).Count != 0)
                        continue;

                    var locale = await Context.Locales.SingleAsync(locale => locale.Id == id, CancellationToken.None);
                    await Context.Entry(locale).ReloadAsync(CancellationToken.None);
                    if (request != null)
                        await BeforeUpdate(locale, request);
                    locale.IsDeleted = true;
                    locale.DeletedAt ??= DateTime.UtcNow;
                    await Context.SaveChangesAsync(CancellationToken.None);
                    await transaction.CommitAsync(CancellationToken.None);
                    _logger.LogInformation("Locale deactivated. LocaleId: {LocaleId}, CancelledCount: {CancelledCount}", id, cancelledCount);
                    return true;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Locale deactivation could not be saved. LocaleId: {LocaleId}, CancelledCount: {CancelledCount}", id, cancelledCount);
                    throw new UserException($"Deaktivacija nije snimljena. Već otkazano rezervacija: {cancelledCount}. Pokušajte ponovo.");
                }
            }
        }

        protected override IQueryable<Locale> ApplyFilter(IQueryable<Locale> query, LocaleSearchObject? search)
        {
            query = query.Include(x => x.City).ThenInclude(x => x.Country)
                         .Include(x => x.Category)
                         .Include(x => x.Owner);

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

            if (search?.Rating.HasValue == true)
                query = query.Where(x => x.Reviews
                    .Where(r => !r.IsDeleted)
                    .Any() && x.Reviews
                    .Where(r => !r.IsDeleted)
                    .Average(r => r.Rating) >= search.Rating.Value);

            if (_currentUser.Role == RoleNames.Vlasnik)
                query = query.Where(x => x.OwnerId == _currentUser.UserId);
            else if (search?.OwnerId.HasValue == true)
                query = query.Where(x => x.OwnerId == search.OwnerId);

            if (string.Equals(search?.SortBy, "rating", StringComparison.OrdinalIgnoreCase))
            {
                query = query
                    .OrderByDescending(locale => locale.Reviews
                        .Where(review => !review.IsDeleted)
                        .Select(review => (double?)review.Rating)
                        .Average() ?? 0)
                    .ThenBy(locale => locale.Id);
            }

            return query;
        }

        protected override IQueryable<Locale> ApplySort(IQueryable<Locale> query, LocaleSearchObject search)
        {
            if (string.Equals(search?.SortBy, "rating", StringComparison.OrdinalIgnoreCase))
                return query;

            return string.IsNullOrWhiteSpace(search?.SortBy)
                ? query.OrderByDescending(x => x.Id)
                : base.ApplySort(query, search);
        }

        protected override async Task BeforeInsert(Locale entity, LocaleInsertRequest request)
        {
            if (_currentUser.Role == RoleNames.Vlasnik)
                entity.OwnerId = _currentUser.UserId;

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

            if (request.ReservationPrice.HasValue)
                entity.ReservationPrice = request.ReservationPrice.Value;

            if (request.Logo == "")
                entity.Logo = null;
            else if (!string.IsNullOrWhiteSpace(request.Logo))
                entity.Logo = request.Logo;

            if (request.IsDeleted.HasValue)
                entity.IsDeleted = request.IsDeleted.Value;

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

            if (request.IsDeleted == false)
                entity.DeletedAt = null;

            await Task.CompletedTask;
        }

        private async Task ValidateUpdateReferencesAsync(Locale entity, LocaleUpdateRequest request)
        {
            if (!await Context.Cities.AnyAsync(city => city.Id == (request.CityId ?? entity.CityId)))
                throw new UserException("Odabrani grad ne postoji.");
            if (!await Context.Categories.AnyAsync(category => category.Id == (request.CategoryId ?? entity.CategoryId)))
                throw new UserException("Odabrana kategorija ne postoji.");
        }
    }
}
