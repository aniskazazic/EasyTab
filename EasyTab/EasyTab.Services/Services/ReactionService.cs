using EasyTab.Model.Models;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System.Linq;
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

        protected override IQueryable<Reaction> ApplyFilter(IQueryable<Reaction> query, ReactionSearchObject? search)
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

        public async Task<Reactions> ReactAsync(int reviewId, bool isLike)
        {
            var userId = _currentUser.UserId;

            var existing = await Context.Reactions
                .FirstOrDefaultAsync(r => r.ReviewId == reviewId && r.UserId == userId);

            if (existing != null)
            {
                // Ako je ista reakcija — ignoriši
                if (existing.IsLike == isLike)
                {
                    return Mapper.Map<Reactions>(existing);
                }

                // Ako je različita reakcija — update
                existing.IsLike = isLike;
                await Context.SaveChangesAsync();
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
            await Context.SaveChangesAsync();
            _logger.LogInformation("Reaction created. UserId: {UserId}, ReviewId: {ReviewId}", userId, reviewId);

            return Mapper.Map<Reactions>(newReaction);
        }

        public async Task RemoveReactionAsync(int reviewId)
        {
            var userId = _currentUser.UserId;

            var reaction = await Context.Reactions
                .FirstOrDefaultAsync(r => r.ReviewId == reviewId && r.UserId == userId);

            if (reaction == null)
            {
                _logger.LogWarning("Reaction not found. UserId: {UserId}, ReviewId: {ReviewId}", userId, reviewId);
                throw new UserException("Reakcija nije pronađena!");
            }

            Context.Reactions.Remove(reaction);
            await Context.SaveChangesAsync();
            _logger.LogInformation("Reaction removed. UserId: {UserId}, ReviewId: {ReviewId}", userId, reviewId);
        }

        public async Task<ReactionsCount> GetReactionCountsAsync(int reviewId)
        {
            var counts = new ReactionsCount
            {
                Likes = await Context.Reactions.CountAsync(r => r.ReviewId == reviewId && r.IsLike),
                Dislikes = await Context.Reactions.CountAsync(r => r.ReviewId == reviewId && !r.IsLike)
            };

            return counts;
        }
    }
}
