using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace EasyTab.Services.Services
{
    public class WorkerService : BaseCRUDService<Workers, WorkerSearchObject, Worker, WorkerInsertRequest, WorkerUpdateRequest>, IWorkerService
    {
        public WorkerService(_220030Context context, IMapper mapper) : base(context, mapper)
        {
        }

        protected override IQueryable<Worker> ApplyFilter(IQueryable<Worker> query, WorkerSearchObject search)
        {
            query = query.Include(x => x.User)
                                    .Include(x => x.Locale);

            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.LocaleId == search.LocaleId);

            if (!string.IsNullOrEmpty(search?.Q))
                query = query.Where(x =>
                    x.User.FirstName.Contains(search.Q) ||
                    x.User.LastName.Contains(search.Q) ||
                    x.User.Username.Contains(search.Q));

            return query;
        }


        protected override async Task BeforeInsert(Worker entity, WorkerInsertRequest request)
        {
            var existingUser = Context.Users
                .FirstOrDefault(x => x.Email == request.Email || x.Username == request.Username);

            if (existingUser != null)
                throw new Exception("Korisnik sa ovim emailom ili korisničkim imenom već postoji!");

            var salt = UserService.GenerateSalt();
            var user = new User
            {
                FirstName = request.FirstName,
                LastName = request.LastName,
                Username = request.Username,
                Email = request.Email,
                PhoneNumber = request.PhoneNumber,
                BirthDate = request.BirthDate,
                IsDeleted = false
            };

            user.PasswordSalt = salt;
            user.PasswordHash = UserService.GenerateHash(user.PasswordSalt, request.Password);

            Context.Users.Add(user);
            await Context.SaveChangesAsync();

            entity.UserId = user.Id;
            entity.HireDate = DateTime.Now;
            entity.LocaleId = request.LocaleId;
        }

        protected override async Task BeforeUpdate(Worker entity, WorkerUpdateRequest request)
        {
            var user = Context.Users.Find(entity.UserId);
            if (user == null) return;

            if (!string.IsNullOrEmpty(request.FirstName))
                user.FirstName = request.FirstName;

            if (!string.IsNullOrEmpty(request.LastName))
                user.LastName = request.LastName;

            if (!string.IsNullOrEmpty(request.Username))
                user.Username = request.Username;

            if (!string.IsNullOrEmpty(request.Email))
                user.Email = request.Email;

            if (!string.IsNullOrEmpty(request.PhoneNumber))
                user.PhoneNumber = request.PhoneNumber;

            if (!string.IsNullOrEmpty(request.Password))
            {
                var salt = UserService.GenerateSalt();
                user.PasswordSalt = salt;
                user.PasswordHash = UserService.GenerateHash(salt, request.Password);
            }

            if (request.HireDate.HasValue)
                entity.HireDate = request.HireDate.Value;

            if (request.BirthDate.HasValue)
                user.BirthDate = request.BirthDate.Value;

            Context.Users.Update(user);
            await Task.CompletedTask;
        }

    }
}
