using EasyTab.Model.Models;
using EasyTab.Services.Database;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.QueryOptimization
{
    public class QueryOptimizationService : IQueryOptimizationService
    {
        private readonly _220030Context _context;
        private readonly IMapper _mapper;

        public QueryOptimizationService(_220030Context context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;

        }
        public async Task<Locales> AsNoTrackingBadQuerry()
        {
            var locale = await _context.Locales.FirstAsync();

            locale.Name = "Updated Name";

            foreach (var entries in _context.ChangeTracker.Entries())
            {
                var entity = entries.Entity;
                //var state = entries.State;
            }

            return _mapper.Map<Locales>(locale);
        }

        public async Task<Locales> AsNoTrackingGoodQuerry()
        {
            var locale = await _context.Locales.AsNoTracking().FirstAsync();

            locale.Name = "Updated Name";

            foreach (var entries in _context.ChangeTracker.Entries())
            {
                var entity = entries.Entity;
                //var state = entries.State;
            }

            return _mapper.Map<Locales>(locale);
        }

        public async Task<List<Locales>> GetFilteredLocalesBadQuerry()
        {
            var locales = await _context.Locales.Include(x=>x.Reviews).ToListAsync();

            var decentLocales = locales.Where(l => l.Reviews.Any(r => r.Rating >= 4)).ToList();

            return decentLocales.Select(x => _mapper.Map<Locales>(x)).ToList();
        }

        public async Task<List<Locales>> GetFilteredLocalesGoodQuerry()
        {
            var locales =  _context.Locales.Include(x => x.Reviews);

            var decentLocales = await locales.Include(x=>x.Reviews).Where(l => l.Reviews.Any(r => r.Rating >= 4)).ToListAsync();

            return decentLocales.Select(x => _mapper.Map<Locales>(x)).ToList();
        }

        public async Task<List<string>> GetFullNamesBadQuerry()
        {
            var fullNames = new List<string>();

            await foreach (var user in _context.Users.AsAsyncEnumerable())
            {
                fullNames.Add($"{user.FirstName} {user.LastName}");
            }

            return fullNames;
        }

        public async Task<List<string>> GetFullNamesGoodQuerry()
        {
            var fullNames = new List<string>();

            await foreach (var userName in _context.Users.Select(u => u.FirstName + " " + u.LastName).AsAsyncEnumerable())
            {
                fullNames.Add(userName);
            }

            return fullNames;
        }

        public async Task<List<Users>> SplittingQueries()
        {
            //        var users = await _context.Users
            //.Include(u => u.UserRoles)
            //.Include(u => u.RefreshTokens)
            //.AsSplitQuery()
            //.ToListAsync();

            //        var userResponses = users.Select(u => _mapper.Map<UserResponse>(u)).ToList();

            //        return userResponses;
            throw new NotImplementedException();
        }

        public async Task<List<Locales>> UsingSqlQueries()
        {
            var products = await _context.Locales
                .FromSqlRaw("SELECT * FROM Locales as L WHERE L.Address = Ulica bb")
                .ToListAsync();

            var productResponses = products.Select(u => _mapper.Map<Locales>(u)).ToList();

            return productResponses;
        }
    }
}
