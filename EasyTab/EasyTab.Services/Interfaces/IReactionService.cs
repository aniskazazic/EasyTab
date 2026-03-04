using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Interfaces;
using Microsoft.AspNetCore.Mvc.ApplicationModels;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IReactionService : ICRUDService<Reactions, ReactionSearchObject, ReactionInsertRequest, ReactionUpdateRequest>
    {
        Reactions React(int reviewId, int userId, bool isLike);
        void RemoveReaction(int reviewId, int userId);
        ReactionsCount GetReactionCounts(int reviewId);
    }
}
