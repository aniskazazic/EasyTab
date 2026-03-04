using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IReviewService  : ICRUDService<Reviews, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        ReviewAverage GetAverageRating(int localeId);
        ReviewRatingCount GetRatingCounts(int localeId);
    }
}
