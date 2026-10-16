using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Interfaces;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IReactionService : ICRUDService<Reactions, ReactionSearchObject, ReactionInsertRequest, ReactionUpdateRequest>
    {
        Task<Reactions> ReactAsync(int reviewId, bool isLike);
        Task RemoveReactionAsync(int reviewId);
        Task<ReactionsCount> GetReactionCountsAsync(int reviewId);
    }
}
