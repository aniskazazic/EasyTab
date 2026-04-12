using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class ReviewService : BaseCRUDService<Reviews, ReviewSearchObject, Review, ReviewInsertRequest, ReviewUpdateRequest>, IReviewService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        public ReviewService(_220030Context context, IMapper mapper, IHttpContextAccessor httpContextAccessor) : base(context, mapper) {
            _httpContextAccessor = httpContextAccessor;
        }

        protected override IQueryable<Review> ApplyFilter(IQueryable<Review> query, ReviewSearchObject search)
        {
            query = query.Include(x => x.User)
                         .Include(x => x.Locale);

            // Po defaultu prikazuj samo aktivne recenzije
            query = query.Where(x => !x.IsDeleted);

            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.LocaleId == search.LocaleId);

            if (search?.IsDeleted.HasValue == true)
                query = query.Where(x => x.IsDeleted == search.IsDeleted);

            //// Sortiranje - zahtijeva join sa Reactions
            //var reactions = Context.Reactions.AsQueryable();

            //var queryWithReactions = query.Select(review => new
            //{
            //    Review = review,
            //    Likes = reactions.Count(r => r.ReviewId == review.Id && r.IsLike),
            //    Dislikes = reactions.Count(r => r.ReviewId == review.Id && !r.IsLike)
            //});

            //queryWithReactions = search?.SortBy?.ToLower() switch
            //{
            //    "mostlikes" => queryWithReactions.OrderByDescending(x => x.Likes),
            //    "mostdislikes" => queryWithReactions.OrderByDescending(x => x.Dislikes),
            //    "highestrating" => queryWithReactions.OrderByDescending(x => x.Review.Rating),
            //    "lowestrating" => queryWithReactions.OrderBy(x => x.Review.Rating),
            //    "latest" => queryWithReactions.OrderByDescending(x => x.Review.DateAdded),
            //    "earliest" => queryWithReactions.OrderBy(x => x.Review.DateAdded),
            //    _ => queryWithReactions.OrderByDescending(x => x.Review.Id)
            //};

            
            //return queryWithReactions.Select(x => x.Review);

            // Jednostavno sortiranje (ne po lajkovima)
            query = search?.SortBy?.ToLower() switch
            {
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

            // Broj lajkova i dislajkova
            dto.Likes = Context.Reactions.Count(r => r.ReviewId == entity.Id && r.IsLike);
            dto.Dislikes = Context.Reactions.Count(r => r.ReviewId == entity.Id && !r.IsLike);

            // Reakcija trenutnog korisnika
            var userIdClaim = _httpContextAccessor.HttpContext?.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (int.TryParse(userIdClaim, out int currentUserId))
            {
                var userReaction = Context.Reactions
                    .FirstOrDefault(r => r.ReviewId == entity.Id && r.UserId == currentUserId);
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

        
        protected override Task BeforeInsert(Review entity, ReviewInsertRequest request)
        {
            if (request.Rating < 1 || request.Rating > 5)
                throw new Exception("Rating mora biti između 1 i 5!");

            if (string.IsNullOrWhiteSpace(request.Description))
                throw new Exception("Opis recenzije je obavezan!");

            // Provjeri da li korisnik već ima recenziju za ovaj lokal
            var existingReview = Context.Reviews
                .FirstOrDefault(r => r.UserId == request.UserId &&
                                     r.LocaleId == request.LocaleId &&
                                     !r.IsDeleted);

            if (existingReview != null)
                throw new Exception("Već ste ostavili recenziju za ovaj lokal!");

            entity.DateAdded = DateTime.Now;
            entity.IsDeleted = false;

            return Task.CompletedTask;

        }

        protected override Task BeforeUpdate(Review entity, ReviewUpdateRequest request)
        {
            if (request.Rating.HasValue && (request.Rating < 1 || request.Rating > 5))
                throw new Exception("Rating mora biti između 1 i 5!");

            if (request.Description != null && string.IsNullOrWhiteSpace(request.Description))
                throw new Exception("Opis recenzije ne može biti prazan!");

            return Task.CompletedTask;
        }

        public ReviewAverage GetAverageRating(int localeId)
        {
            var reviews = Context.Reviews
                .Where(r => r.LocaleId == localeId && !r.IsDeleted)
                .ToList();

            return new ReviewAverage
            {
                AverageRating = reviews.Count == 0 ? 0 : (float)reviews.Average(x => x.Rating)
            };
        }

        public ReviewRatingCount GetRatingCounts(int localeId)
        {
            var reviews = Context.Reviews
                .Where(r => r.LocaleId == localeId && !r.IsDeleted)
                .ToList();

            return new ReviewRatingCount
            {
                Excellent = reviews.Count(r => r.Rating >= 4.5),
                Good = reviews.Count(r => r.Rating >= 3.5 && r.Rating < 4.5),
                Average = reviews.Count(r => r.Rating >= 2.5 && r.Rating < 3.5),
                Poor = reviews.Count(r => r.Rating >= 1.5 && r.Rating < 2.5),
                Terrible = reviews.Count(r => r.Rating < 1.5)
            };
        }
    }
}
