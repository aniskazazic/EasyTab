using EasyTab.Model.Models;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using EasyTab.Services.ReservationStateMachine;

namespace EasyTab.Services.Services
{
    public class ReviewService : BaseCRUDService<Reviews, ReviewSearchObject, Review, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly ICurrentUserService _currentUser;
        private readonly ILogger<ReviewService> _logger;

        public ReviewService(_220030Context context, IMapper mapper, IHttpContextAccessor httpContextAccessor, ICurrentUserService currentUser, ILogger<ReviewService> logger, IValidator<ReviewInsertRequest> insertValidator, IValidator<ReviewUpdateRequest> updateValidator) : base(context, mapper, insertValidator, updateValidator) {
            _httpContextAccessor = httpContextAccessor;
            _currentUser = currentUser;
            _logger = logger;
        }

        public override async Task<Reviews> CreateAsync(ReviewInsertRequest request)
        {
            request.UserId = _currentUser.UserId;
            return await base.CreateAsync(request);
        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            query = query.Include(x => x.User)
                         .Include(x => x.Locale)
                         .Include(x => x.Reactions);

            // Po defaultu prikazuj samo aktivne recenzije
            query = query.Where(x => !x.IsDeleted);

            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.LocaleId == search.LocaleId);

            if (search?.IsDeleted.HasValue == true)
                query = query.Where(x => x.IsDeleted == search.IsDeleted);

            if (search?.UserId.HasValue == true)
                query = query.Where(x => x.UserId == search.UserId);

            if (search?.Rating.HasValue == true)
                query = query.Where(x => x.Rating == search.Rating);

            if (!string.IsNullOrWhiteSpace(search?.Text))
            {
                var text = search.Text.Trim();
                query = query.Where(x =>
                    x.Description.Contains(text) ||
                    (x.User.FirstName + " " + x.User.LastName).Contains(text) ||
                    x.Locale.Name.Contains(text));
            }

            if (search?.DateFrom.HasValue == true)
            {
                var dateFrom = search.DateFrom.Value.ToUniversalTime();
                query = query.Where(x => x.DateAdded >= dateFrom);
            }

            if (search?.DateTo.HasValue == true)
            {
                var dateTo = search.DateTo.Value.ToUniversalTime();
                query = query.Where(x => x.DateAdded < dateTo);
            }

            query = search?.SortBy?.ToLower() switch
            {
                "mostlikes" => query.OrderByDescending(x => x.Reactions.Count(r => r.IsLike)),
                "mostdislikes" => query.OrderByDescending(x => x.Reactions.Count(r => !r.IsLike)),
                "highestrating" => query.OrderByDescending(x => x.Rating),
                "lowestrating" => query.OrderBy(x => x.Rating),
                "latest" => query.OrderByDescending(x => x.DateAdded),
                "earliest" => query.OrderBy(x => x.DateAdded),
                _ => query.OrderByDescending(x => x.Id)
            };

            return query;
        }

        // Ovdje dodajemo Likes, Dislikes i UserReaction
        protected override Reviews MapToResponse(Review entity)
        {
            var dto = base.MapToResponse(entity); // Mapster mapira osnovna polja

            // Popuni user podatke
            if (entity.User != null)
            {
                dto.UserFullName = $"{entity.User.FirstName} {entity.User.LastName}";
            }

            // Broj lajkova i dislajkova - koristi učitane Reactions iz memorije
            dto.Likes = entity.Reactions?.Count(r => r.IsLike) ?? 0;
            dto.Dislikes = entity.Reactions?.Count(r => !r.IsLike) ?? 0;

            // Reakcija trenutnog korisnika
            var userIdClaim = _httpContextAccessor.HttpContext?.User?.FindFirst("Id")?.Value;
            if (int.TryParse(userIdClaim, out int currentUserId))
            {
                var userReaction = entity.Reactions?.FirstOrDefault(r => r.UserId == currentUserId);
                if (userReaction != null)
                    dto.UserReaction = userReaction.IsLike ? 1 : -1;
                else
                    dto.UserReaction = 0;
            }
            else
            {
                dto.UserReaction = 0;
            }

            return dto;
        }

        
        public async Task<CanReviewResponse> CanReviewAsync(int localeId)
        {
            var userId = _currentUser.UserId;
            var hasCompletedReservation = await HasCompletedReservationAsync(userId, localeId);

            if (!hasCompletedReservation)
            {
                return new CanReviewResponse
                {
                    CanReview = false,
                    Reason = "Potrebna je najmanje jedna završena rezervacija u ovom lokalu."
                };
            }

            var hasReview = await Context.Reviews.AnyAsync(r =>
                r.UserId == userId &&
                r.LocaleId == localeId &&
                !r.IsDeleted);

            return hasReview
                ? new CanReviewResponse
                {
                    CanReview = false,
                    Reason = "Već ste ostavili recenziju za ovaj lokal."
                }
                : new CanReviewResponse { CanReview = true };
        }

        protected override async Task BeforeInsert(Review entity, ReviewInsertRequest request)
        {
            _logger.LogInformation("Creating review. LocaleId: {LocaleId}, UserId: {UserId}", request.LocaleId, request.UserId);

            if (request.Rating < 1 || request.Rating > 5)
                throw new UserException("Ocjena mora biti između 1 i 5!");

            if (string.IsNullOrWhiteSpace(request.Description))
                throw new UserException("Opis recenzije je obavezan!");

            var hasCompletedReservation = await HasCompletedReservationAsync(
                request.UserId,
                request.LocaleId);

            if (!hasCompletedReservation)
                throw new UserException("Recenziju možete ostaviti tek nakon završene rezervacije u ovom lokalu.");

            // Provjeri da li korisnik već ima recenziju za ovaj lokal
            var existingReview = await Context.Reviews
                .FirstOrDefaultAsync(r => r.UserId == request.UserId &&
                                          r.LocaleId == request.LocaleId &&
                                          !r.IsDeleted);

            if (existingReview != null)
            {
                _logger.LogWarning("Duplicate review prevented. LocaleId: {LocaleId}, UserId: {UserId}", request.LocaleId, request.UserId);
                throw new UserException("Već ste ostavili recenziju za ovaj lokal!");
            }

            entity.DateAdded = DateTime.UtcNow;
            entity.IsDeleted = false;
        }

        protected override Task BeforeUpdate(Review entity, ReviewUpdateRequest request)
        {
            EnsureOwnership(entity);
            _logger.LogInformation("Updating review. ReviewId: {ReviewId}", entity.Id);

            if (request.Rating.HasValue && (request.Rating < 1 || request.Rating > 5))
                throw new UserException("Ocjena mora biti između 1 i 5!");

            if (request.Description != null && string.IsNullOrWhiteSpace(request.Description))
                throw new UserException("Opis recenzije ne može biti prazan!");

            return Task.CompletedTask;
        }

        protected override async Task BeforeDelete(Review entity)
        {
            if (_currentUser.IsAdmin || entity.UserId == _currentUser.UserId)
                return;

            var isLocaleOwner = await Context.Locales.AnyAsync(l => l.Id == entity.LocaleId && l.OwnerId == _currentUser.UserId);
            if (!isLocaleOwner)
                throw new UnauthorizedAccessException("Nemate dozvolu za ovu akciju.");
        }

        private void EnsureOwnership(Review entity)
        {
            if (!_currentUser.IsAdmin && entity.UserId != _currentUser.UserId)
                throw new UnauthorizedAccessException("Nemate dozvolu za ovu akciju.");
        }

        private Task<bool> HasCompletedReservationAsync(int userId, int localeId)
        {
            return Context.Reservations.AnyAsync(r =>
                r.UserId == userId &&
                r.ReservationState == CompletedReservationState.StateName &&
                r.Table.LocaleId == localeId);
        }

        public async Task<ReviewAverage> GetAverageRatingAsync(int localeId)
        {
            var reviews = await Context.Reviews
                .Where(r => r.LocaleId == localeId && !r.IsDeleted)
                .ToListAsync();

            var result = new ReviewAverage
            {
                AverageRating = reviews.Count == 0 ? 0 : (float)reviews.Average(x => x.Rating)
            };

            _logger.LogDebug("Average rating fetched. LocaleId: {LocaleId}, Average: {Average}", localeId, result.AverageRating);
            return result;
        }

        public async Task<ReviewRatingCount> GetRatingCountsAsync(int localeId)
        {
            var reviews = await Context.Reviews
                .Where(r => r.LocaleId == localeId && !r.IsDeleted)
                .ToListAsync();

            var counts = new ReviewRatingCount
            {
                Excellent = reviews.Count(r => r.Rating >= 4.5),
                Good = reviews.Count(r => r.Rating >= 3.5 && r.Rating < 4.5),
                Average = reviews.Count(r => r.Rating >= 2.5 && r.Rating < 3.5),
                Poor = reviews.Count(r => r.Rating >= 1.5 && r.Rating < 2.5),
                Terrible = reviews.Count(r => r.Rating < 1.5)
            };

            _logger.LogDebug("Rating distribution fetched. LocaleId: {LocaleId}", localeId);
            return counts;
        }

        public async Task<List<Reviews>> GetByLocaleId(int localeId)
        {
            var entities = await Context.Reviews
                .Include(r => r.User)
                .Include(r => r.Locale)
                .Include(r => r.Reactions)
                .Where(r => r.LocaleId == localeId && !r.IsDeleted)
                .OrderByDescending(r => r.DateAdded)
                .ToListAsync();

            var dtos = entities.Select(e => MapToResponse(e)).ToList();
            return dtos;
        }
    }
}
