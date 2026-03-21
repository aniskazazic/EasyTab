using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;


namespace EasyTab.Services.Services
{
    public class WorkerService : BaseCRUDService<Workers, WorkerSearchObject, Worker, WorkerInsertRequest, WorkerUpdateRequest>, IWorkerService
    {
        private readonly string _baseUrl;

        public WorkerService(_220030Context context, IMapper mapper, IConfiguration config) : base(context, mapper)
        {
            _baseUrl = config["APP_BASE_URL"] ?? "http://localhost:5241";
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

        protected override Workers MapToResponse(Worker entity)
        {
            return new Workers
            {
                Id = entity.Id,
                UserId = entity.UserId,
                FirstName = entity.User?.FirstName,
                LastName = entity.User?.LastName,
                Username = entity.User?.Username,
                Email = entity.User?.Email,
                PhoneNumber = entity.User?.PhoneNumber,
                BirthDate = entity.User?.BirthDate,
                ProfilePicture = !string.IsNullOrEmpty(entity.User?.ProfilePicture)
                    ? $"{_baseUrl}/ImageFolder/ProfilePictures/{entity.User.ProfilePicture}"
                    : null,
                HireDate = entity.HireDate,
                EndDate = entity.EndDate,
                LocaleId = entity.LocaleId,
                LocaleName = entity.Locale?.Name,
            };
        }

        public override async Task<Workers> CreateAsync(WorkerInsertRequest request)
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
                DeletedAt = null,
                IsDeleted = false,
                ProfilePicture = string.IsNullOrWhiteSpace(request.ProfilePicture)
                    ? null
                    : Path.GetFileName(request.ProfilePicture),
                PasswordSalt = salt,
            };
            user.PasswordHash = UserService.GenerateHash(salt, request.Password);

            Context.Users.Add(user);
            await Context.SaveChangesAsync();

            var worker = new Worker
            {
                UserId = user.Id,
                LocaleId = request.LocaleId,
                HireDate = DateTime.Now,
                EndDate = null,
            };

            Context.Workers.Add(worker);
            await Context.SaveChangesAsync();

            var workerRole = Context.Roles.FirstOrDefault(r => r.Name == "Worker");
            if (workerRole != null)
            {
                Context.UserRoles.Add(new UserRole
                {
                    UserId = user.Id,
                    RoleId = workerRole.Id
                });
                await Context.SaveChangesAsync();
            }

            return new Workers
            {
                Id = worker.Id,
                UserId = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Username = user.Username,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                BirthDate = user.BirthDate,
                ProfilePicture = !string.IsNullOrEmpty(user.ProfilePicture)
                    ? $"{_baseUrl}/ImageFolder/ProfilePictures/{user.ProfilePicture}"
                    : null,
                HireDate = worker.HireDate,
                EndDate = worker.EndDate,
                LocaleId = worker.LocaleId,
            };
        }

        public override async Task<Workers?> UpdateAsync(int id, WorkerUpdateRequest request)
        {
            var worker = await Context.Workers
                .Include(x => x.User)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (worker == null) return null;

            var user = worker.User;

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

            // Uzimamo samo filename kao u UserService
            if (!string.IsNullOrEmpty(request.ProfilePicture))
                user.ProfilePicture = Path.GetFileName(request.ProfilePicture);

            if (request.BirthDate.HasValue && request.BirthDate.Value > new DateTime(1753, 1, 1))
                user.BirthDate = request.BirthDate.Value;

            if (!string.IsNullOrEmpty(request.Password))
            {
                var salt = UserService.GenerateSalt();
                user.PasswordSalt = salt;
                user.PasswordHash = UserService.GenerateHash(salt, request.Password);
            }

            Context.Users.Update(user);
            await Context.SaveChangesAsync();

            return MapToResponse(worker);
        }

        protected override async Task BeforeInsert(Worker entity, WorkerInsertRequest request)
        {
            await Task.CompletedTask;
        }

        protected override async Task BeforeUpdate(Worker entity, WorkerUpdateRequest request)
        {
            await Task.CompletedTask;
        }
    }
}
