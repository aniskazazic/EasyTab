using EasyTab.Model.Models;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.AspNetCore.Mvc.ApplicationModels;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace EasyTab.Services.Services
{
    public class ReactionService : BaseCRUDService<Reactions, ReactionSearchObject, Reaction, ReactionInsertRequest, ReactionUpdateRequest>, IReactionService
    {
        private readonly ILogger<ReactionService> _logger;
        private readonly ICurrentUserService _currentUser;

        public ReactionService(_220030Context context, IMapper mapper, ILogger<ReactionService> logger, IValidator<ReactionInsertRequest> insertValidator, IValidator<ReactionUpdateRequest> updateValidator, ICurrentUserService currentUser) : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
            _currentUser = currentUser;
        }

        protected override IQueryable<Reaction> ApplyFilter(IQueryable<Reaction> query, ReactionSearchObject search)
        {
            if (search?.ReviewId.HasValue == true)
                query = query.Where(x => x.ReviewId == search.ReviewId);

            var filterUserId = _currentUser.IsAdmin && search?.UserId.HasValue == true
                ? search.UserId.Value
                : _currentUser.UserId;
            query = query.Where(x => x.UserId == filterUserId);

            return query;
        }

        public override async Task<Reactions?> GetByIdAsync(int id)
        {
            var entity = await Context.Reactions.FirstOrDefaultAsync(x => x.Id == id);
            if (entity == null || (!_currentUser.IsAdmin && entity.UserId != _currentUser.UserId))
                return null;

            return Mapper.Map<Reactions>(entity);
        }

        public Reactions React(int reviewId, bool isLike)
        {
            var userId = _currentUser.UserId;

            var existing = Context.Reactions
                            .FirstOrDefault(r => r.ReviewId == reviewId && r.UserId == userId);

            if (existing != null)
            {
                // Ako je ista reakcija — ignoriši
                if (existing.IsLike == isLike)
                {
                    return Mapper.Map<Reactions>(existing);
                }

                // Ako je različita reakcija — update
                existing.IsLike = isLike;
                Context.SaveChanges();
                return Mapper.Map<Reactions>(existing);
            }

            // Nova reakcija
            var newReaction = new Reaction
            {
                ReviewId = reviewId,
                UserId = userId,
                IsLike = isLike
            };

            Context.Reactions.Add(newReaction);
            Context.SaveChanges();
            _logger.LogInformation("Reaction created. UserId: {UserId}, ReviewId: {ReviewId}", userId, reviewId);

            return Mapper.Map<Reactions>(newReaction);
        }

        public void RemoveReaction(int reviewId)
        {
            var userId = _currentUser.UserId;

            var reaction = Context.Reactions
                .FirstOrDefault(r => r.ReviewId == reviewId && r.UserId == userId);

            if (reaction == null)
            {
                _logger.LogWarning("Reaction not found. UserId: {UserId}, ReviewId: {ReviewId}", userId, reviewId);
                throw new UserException("Reakcija nije pronađena!");
            }

            Context.Reactions.Remove(reaction);
            Context.SaveChanges();
            _logger.LogWarning("Reaction removed. UserId: {UserId}, ReviewId: {ReviewId}", userId, reviewId);
        }

        public ReactionsCount GetReactionCounts(int reviewId)
        {
            var counts = new ReactionsCount
            {
                Likes = Context.Reactions.Count(r => r.ReviewId == reviewId && r.IsLike),
                Dislikes = Context.Reactions.Count(r => r.ReviewId == reviewId && !r.IsLike)
            };

            return counts;
        }
    }
}
