using EasyTab.Common.Services.CryptoService;
using EasyTab.Model.Access;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace EasyTab.Services.Services
{
    public class UserService : BaseCRUDService<Users, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        private readonly ILogger<IUserService> _logger;
        private readonly ICryptoService _cryptoService;

        public UserService(_220030Context context, IMapper mapper, ILogger<IUserService> logger, IValidator<UserInsertRequest> insertValidator, IValidator<UserUpdateRequest> updateValidator, ICryptoService cryptoService) : base(context, mapper,insertValidator,updateValidator)
        {
            _logger = logger;
            _cryptoService = cryptoService;
        }

        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject? searchObject)
        {
            query = query.Include(x => x.UserRoles)
                 .ThenInclude(y => y.Role);

            // Ako IsDeleted nije true (checkbox nije čekiran) — prikaži samo aktivne
            // Ako IsDeleted == true (checkbox čekiran) — prikaži SVE (aktivne + obrisane)
            if (searchObject?.IsDeleted != true)
                query = query.Where(x => !x.IsDeleted);

            if (!string.IsNullOrEmpty(searchObject?.FirstNameGTE))
                query = query.Where(x => x.FirstName.StartsWith(searchObject.FirstNameGTE));

            if (!string.IsNullOrEmpty(searchObject?.LastNameGTE))
                query = query.Where(x => x.LastName.StartsWith(searchObject.LastNameGTE));

            if (!string.IsNullOrEmpty(searchObject?.Username))
                query = query.Where(x => x.Username == searchObject.Username);

            if (!string.IsNullOrEmpty(searchObject?.Email))
                query = query.Where(x => x.Email == searchObject.Email);

            if (!string.IsNullOrEmpty(searchObject?.FTS))
                query = query.Where(x =>
                    x.FirstName.Contains(searchObject.FTS) ||
                    x.LastName.Contains(searchObject.FTS) ||
                    x.Email.Contains(searchObject.FTS) ||
                    x.Username.Contains(searchObject.FTS));

            return query;
        }

        protected override Users MapToResponse(User entity)
        {
            var model = base.MapToResponse(entity);
            model.ProfilePicture = entity.ProfilePicture;
            return model;
        }

        public override async Task<Users> CreateAsync(UserInsertRequest request)
        {
            var result = await base.CreateAsync(request);

            if (request.RoleIds != null && request.RoleIds.Count > 0)
            {
                var user = await Context.Users.FirstOrDefaultAsync(u => u.Username == request.Username);
                if (user != null)
                {
                    foreach (var roleId in request.RoleIds)
                    {
                        if (await Context.Roles.AnyAsync(r => r.Id == roleId))
                        {
                            Context.UserRoles.Add(new UserRole
                            {
                                UserId = user.Id,
                                RoleId = roleId
                            });
                        }
                    }
                    await Context.SaveChangesAsync();
                }
            }

            return result;
        }

        protected override async Task BeforeInsert(User entity, UserInsertRequest request)
        {

            await _insertValidator.ValidateAndThrowAsync(request);

            // Check if email or username already exists
            if (await _context.Users.AnyAsync(u => u.Email == request.Email))
            {
                throw new UserException($"Email '{request.Email}' je već u upotrebi.");
            }

            if (await _context.Users.AnyAsync(u => u.Username == request.Username))
            {
                throw new UserException($"Korisničko ime '{request.Username}' je već u upotrebi.");
            }

            entity.PasswordSalt = _cryptoService.GenerateSalt();
            entity.PasswordHash = _cryptoService.GenerateHash(request.Password, entity.PasswordSalt);
            entity.IsDeleted = false;
            entity.ProfilePicture = string.IsNullOrWhiteSpace(request.ProfilePicture)
                ? null
                : request.ProfilePicture;

            await Task.CompletedTask;
        }

        public override async Task<Users?> UpdateAsync(int id, UserUpdateRequest request)
        {
            await _updateValidator.ValidateAndThrowAsync(request);

            var entity = await _context.Users.FindAsync(id);
            if (entity == null)
            {
                _logger.LogWarning("User not found for update. UserId: {UserId}", id);
                throw new UserException($"Korisnik sa ID {id} nije pronađen.");
            }

            // Check if email or username already exists
            if (await _context.Users.AnyAsync(u => u.Email == request.Email && u.Id != id))
            {
                throw new UserException($"Email '{request.Email}' je već u upotrebi.");
            }

            if (await _context.Users.AnyAsync(u => u.Username == request.Username && u.Id != id))
            {
                throw new UserException($"Korisničko ime '{request.Username}' je već u upotrebi.");
            }

            var oldEmail = entity.Email;
            var oldFirstName = entity.FirstName;
            var oldLastName = entity.LastName;
            var oldPhoneNumber = entity.PhoneNumber;
            var oldBirthDate = entity.BirthDate;
            var oldProfilePicture = entity.ProfilePicture;
            var oldIsDeleted = entity.IsDeleted;
            var oldPasswordHash = entity.PasswordHash;
            var oldPasswordSalt = entity.PasswordSalt;
            var oldUsername = entity.Username;

            Mapper.Map(request, entity);

            if (string.IsNullOrWhiteSpace(request.FirstName))
                entity.FirstName = oldFirstName;

            if (string.IsNullOrWhiteSpace(request.LastName))
                entity.LastName = oldLastName;

            if (string.IsNullOrWhiteSpace(request.Username))
                entity.Username = oldUsername;

            if (string.IsNullOrWhiteSpace(request.Email))
                entity.Email = oldEmail;

            if (string.IsNullOrWhiteSpace(request.PhoneNumber))
                entity.PhoneNumber = oldPhoneNumber;

            if (!request.BirthDate.HasValue)
                entity.BirthDate = oldBirthDate;

            if (request.ProfilePicture == "")
                entity.ProfilePicture = null;
            else if (!string.IsNullOrWhiteSpace(request.ProfilePicture))
                entity.ProfilePicture = request.ProfilePicture;
            else
                entity.ProfilePicture = oldProfilePicture;

            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                if (request.Password != request.PasswordConfirmation)
                    throw new UserException("Lozinka i potvrda lozinke moraju biti iste!");
                entity.PasswordSalt = _cryptoService.GenerateSalt();
                entity.PasswordHash = _cryptoService.GenerateHash(request.Password, entity.PasswordSalt);
            }
            else
            {
                entity.PasswordHash = oldPasswordHash;
                entity.PasswordSalt = oldPasswordSalt;
            }

            if (!request.IsDeleted.HasValue)
            {
                entity.IsDeleted = oldIsDeleted;
            }
            else if (request.IsDeleted == false)
            {
                entity.IsDeleted = false;
                entity.DeletedAt = null;

                // Reaktiviraj Worker ako postoji
                var worker = await _context.Workers
                    .FirstOrDefaultAsync(x => x.UserId == id);
                if (worker != null)
                {
                    worker.IsDeleted = false;
                    worker.DeletedAt = null;
                    worker.EndDate = null;
                }

                // Reaktiviraj UserRoles
                var userRoles = await _context.UserRoles
                    .Where(x => x.UserId == id)
                    .ToListAsync();
                foreach (var role in userRoles)
                {
                    role.IsDeleted = false;
                    role.DeletedAt = null;
                }
            }
            else
            {
                entity.IsDeleted = true;
            }

            await _context.SaveChangesAsync();
            _logger.LogInformation("User updated successfully. UserId: {UserId}", id);
            return Mapper.Map<Users>(entity);
        }


        protected override async Task BeforeUpdate(User entity, UserUpdateRequest request)
        {
            await Task.CompletedTask;
        }

        public override async Task<bool> DeleteAsync(int id)
        {
            var user = await _context.Users
                .Include(x => x.UserRoles)
                .FirstOrDefaultAsync(x => x.Id == id);

            if (user == null)
            {
                _logger.LogWarning("User not found for delete. UserId: {UserId}", id);
                throw new UserException("Korisnik nije pronađen");
            }

            // Soft delete User
            user.IsDeleted = true;
            user.DeletedAt = DateTime.UtcNow;

            // Soft delete UserRoles
            foreach (var role in user.UserRoles)
            {
                role.IsDeleted = true;
                role.DeletedAt = DateTime.UtcNow;
            }

            // Soft delete Worker — direktno iz Context, ne preko navigacije
            var worker = await _context.Workers
                .FirstOrDefaultAsync(x => x.UserId == id);
            if (worker != null)
            {
                worker.IsDeleted = true;
                worker.DeletedAt = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync();
            _logger.LogWarning("User deleted successfully. UserId: {UserId}", id);
            return true;
        }

        public async Task<UsersSensitiveResponse?> GetByUsernameAsync(string username)
        {
            var user = await _context.Users
                .AsNoTracking()
                .Include(x=>x.UserRoles)
                .ThenInclude(x=>x.Role)
                .FirstOrDefaultAsync(x => x.Username == username);

            UsersSensitiveResponse? response = null;

            if (user != null)
            {
                response = Mapper.Map<UsersSensitiveResponse>(user);
                response.Role = user.UserRoles.First().Role.Name;
            }

            return response;

        }

        public async Task<Users?> GetWithRoleByIdAsync(int id)
        {
            var user = await _context.Users
            .AsNoTracking()
            .Include(x => x.UserRoles)
            .ThenInclude(x => x.Role)
            .FirstOrDefaultAsync(x => x.Id == id);


            Users? response = null;

            if (user != null)
            {
                response = Mapper.Map<Users>(user);
                response.Role = user.UserRoles.First().Role.Name;
            }

            return response;
        }
    }
}