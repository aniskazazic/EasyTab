using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Interfaces;
using Microsoft.AspNetCore.Mvc;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IReviewService  : ICRUDService<Reviews, ReviewSearchObject, ReviewInsertRequest, ReviewUpdateRequest>
    {
        Task<ReviewAverage> GetAverageRatingAsync(int localeId);
        Task<ReviewRatingCount> GetRatingCountsAsync(int localeId);

        Task<List<Reviews>> GetByLocaleId(int localeId);
    }
}
