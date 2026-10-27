using EasyTab.Common.Services.CryptoService;
using EasyTab.Model;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.Validators;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using System;
using System.Linq;
using System.Threading.Tasks;


namespace EasyTab.Services.Services
{
    public class WorkerService : BaseCRUDService<Workers, WorkerSearchObject, Worker, WorkerInsertRequest, WorkerUpdateRequest>, IWorkerService
    {
        private readonly ICryptoService _cryptoService;
        private readonly ILocaleAccessService _localeAccessService;
        private readonly ICurrentUserService _currentUser;

        public WorkerService(_220030Context context, IMapper mapper, ICryptoService cryptoService, IValidator<WorkerInsertRequest> insertValidator, IValidator<WorkerUpdateRequest> updateValidator, ILocaleAccessService localeAccessService, ICurrentUserService currentUser) : base(context, mapper,insertValidator,updateValidator)
        {
            _cryptoService = cryptoService;
            _localeAccessService = localeAccessService;
            _currentUser = currentUser;
        }

        protected override IQueryable<Worker> ApplyFilter(IQueryable<Worker> query, WorkerSearchObject? search)
        {
            query = query.Include(x => x.User)
                         .Include(x => x.Locale);

            query = query.Where(x => !x.IsDeleted);

            var localeIds = _localeAccessService.GetAccessibleLocaleIds();
            query = query.Where(worker => localeIds.Contains(worker.LocaleId));

            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.LocaleId == search.LocaleId);

            if (!string.IsNullOrEmpty(search?.Q))
                query = query.Where(x =>
                    x.User.FirstName.Contains(search.Q) ||
                    x.User.LastName.Contains(search.Q) ||
                    x.User.Username.Contains(search.Q) ||
                    x.User.Email.Contains(search.Q));

            return query;
        }

        protected override IQueryable<Worker> ApplySort(IQueryable<Worker> query, WorkerSearchObject search)
        {
            return string.IsNullOrWhiteSpace(search?.SortBy)
                ? query.OrderByDescending(x => x.Id)
                : base.ApplySort(query, search);
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
                ProfilePicture = entity.User?.ProfilePicture,
                HireDate = entity.HireDate,
                EndDate = entity.EndDate,
                LocaleId = entity.LocaleId,
                LocaleName = entity.Locale?.Name,
            };
        }

        public override async Task<PagedResult<Workers>> GetAsync(WorkerSearchObject search)
        {
            var result = await base.GetAsync(search);
            foreach (var worker in result.Items)
                worker.ProfilePicture = null;

            return result;
        }

        public override async Task<Workers> CreateAsync(WorkerInsertRequest request)
        {
            await _insertValidator.ValidateForUserAsync(request);
            ImageContentValidator.ValidateOptionalImage(
                request.ProfilePicture,
                nameof(request.ProfilePicture));

            await _localeAccessService.EnsureCanManageLocaleAsOwnerAsync(request.LocaleId);

            if (!await Context.Locales.AnyAsync(locale => locale.Id == request.LocaleId && !locale.IsDeleted))
                throw new UserException("Odabrani lokal ne postoji ili je obrisan.");

            var existingUser = await Context.Users
                .FirstOrDefaultAsync(x => x.Email == request.Email || x.Username == request.Username);

            if (existingUser != null)
                throw new UserException("Korisnik sa ovim emailom ili korisničkim imenom već postoji!");

            var salt = _cryptoService.GenerateSalt();
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
                    : request.ProfilePicture,
                PasswordSalt = salt,
            };
            user.PasswordHash = _cryptoService.GenerateHash(request.Password,salt);

            Context.Users.Add(user);

            var worker = new Worker
            {
                User = user,
                LocaleId = request.LocaleId,
                HireDate = DateTime.UtcNow,
                EndDate = null,
            };

            Context.Workers.Add(worker);


            if (_currentUser.IsAdmin && request.RoleIds != null && request.RoleIds.Any())
            {
                foreach (var roleId in request.RoleIds)
                {
                    if (await Context.Roles.AnyAsync(r => r.Id == roleId))
                    {
                        Context.UserRoles.Add(new UserRole
                        {
                            User = user,
                            RoleId = roleId
                        });
                    }
                }
            }
            else
            {
                var workerRole = await Context.Roles.FirstOrDefaultAsync(r => r.Name == RoleNames.Radnik)
                    ?? throw new UserException("Rola radnika nije pronađena.");
                Context.UserRoles.Add(new UserRole
                {
                    User = user,
                    RoleId = workerRole.Id
                });
            }

            await Context.SaveChangesAsync();

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
                ProfilePicture = user.ProfilePicture,
                HireDate = worker.HireDate,
                EndDate = worker.EndDate,
                LocaleId = worker.LocaleId,
            };
        }

        public override async Task<Workers?> UpdateAsync(int id, WorkerUpdateRequest request)
        {
            ImageContentValidator.ValidateOptionalImage(
                request.ProfilePicture,
                nameof(request.ProfilePicture));

            var worker = await Context.Workers
                .Include(x => x.User)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (worker == null) return null;

            await _localeAccessService.EnsureCanManageLocaleAsOwnerAsync(worker.LocaleId);

            await _updateValidator.ValidateForUserAsync(request);

            if (await Context.Users.AnyAsync(user => user.Id != worker.UserId &&
                ((!string.IsNullOrEmpty(request.Email) && user.Email == request.Email) ||
                 (!string.IsNullOrEmpty(request.Username) && user.Username == request.Username))))
                throw new UserException("Korisnik sa ovim emailom ili korisničkim imenom već postoji!");

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

            if (request.ProfilePicture == "")
                user.ProfilePicture = null;
            else if (!string.IsNullOrEmpty(request.ProfilePicture))
                user.ProfilePicture = request.ProfilePicture;

            if (request.BirthDate.HasValue && request.BirthDate.Value > new DateTime(1753, 1, 1))
                user.BirthDate = request.BirthDate.Value;

            if (!string.IsNullOrEmpty(request.Password))
            {
                var salt = _cryptoService.GenerateSalt();
                user.PasswordSalt = salt;
                user.PasswordHash = _cryptoService.GenerateHash(request.Password, salt);
            }

            Context.Users.Update(user);
            await Context.SaveChangesAsync();

            return MapToResponse(worker);
        }

        public override async Task<Workers?> GetByIdAsync(int id)
        {
            var worker = await Context.Workers
                .Include(x => x.User)
                .Include(x => x.Locale)
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == id);

            if (worker == null)
                return null;

            await _localeAccessService.EnsureCanManageLocaleAsync(worker.LocaleId);
            return MapToResponse(worker);
        }

        public override async Task<bool> DeleteAsync(int id)
        {

            var worker = await Context.Workers
                .Include(x => x.User)
                .ThenInclude(u => u.UserRoles)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (worker == null)
                throw new UserException("Radnik nije pronađen");

            await _localeAccessService.EnsureCanManageLocaleAsOwnerAsync(worker.LocaleId);

            // 1. Soft delete Worker
            worker.IsDeleted = true;
            worker.DeletedAt = DateTime.UtcNow;
            worker.EndDate = DateTime.UtcNow;

            // 2. Soft delete User
            if (worker.User != null)
            {
                worker.User.IsDeleted = true;
                worker.User.DeletedAt = DateTime.UtcNow;

                // 3. Soft delete UserRoles
                foreach (var userRole in worker.User.UserRoles)
                {
                    userRole.IsDeleted = true;
                    userRole.DeletedAt = DateTime.UtcNow;
                }
            }

            await Context.SaveChangesAsync();
            return true;
        }
    }
}
