using EasyTab.Model;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObject;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class UserService : BaseCRUDService<Users, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        ILogger<IUserService> _logger;
        private readonly string _baseUrl;

        public UserService(_220030Context context, IMapper mapper, ILogger<IUserService> logger, IConfiguration config) : base(context, mapper)
        {
            _logger = logger;
            _baseUrl = config["APP_BASE_URL"] ?? "http://localhost:5241";
        }

        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject searchObject)
        {
            query = query.Include(x => x.UserRoles)
                 .ThenInclude(y => y.Role);

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

            if (searchObject?.IsDeleted == true)
                query = query.Where(x => x.IsDeleted == searchObject.IsDeleted);

            return query;
        }

        // Baza ima samo filename — konstruisi puni URL za Flutter
        protected override Users MapToResponse(User entity)
        {
            var model = base.MapToResponse(entity);
            if (!string.IsNullOrEmpty(entity.ProfilePicture))
                model.ProfilePicture = $"{_baseUrl}/ImageFolder/ProfilePictures/{entity.ProfilePicture}";
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
            _logger.LogInformation("Inserting user with username: {Username}", request.Username);

            if (request.Password != request.PasswordConfirmation)
                throw new UserException("Lozinka i potvrda lozinke moraju biti iste!");

            if (await Context.Users.AnyAsync(u => u.Email == request.Email))
                throw new UserException("Korisnik sa ovim emailom već postoji!");

            if (await Context.Users.AnyAsync(u => u.Username == request.Username))
                throw new UserException("Korisnik sa ovim korisničkim imenom već postoji!");

            entity.PasswordSalt = GenerateSalt();
            entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
            entity.IsDeleted = false;
            // FileController vraca puni URL — uzimamo samo filename za bazu
            entity.ProfilePicture = string.IsNullOrWhiteSpace(request.ProfilePicture)
                ? null
                : Path.GetFileName(request.ProfilePicture);

            await Task.CompletedTask;
        }

        public override async Task<Users?> UpdateAsync(int id, UserUpdateRequest request)
        {
            var entity = await _context.Set<User>()
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(x => x.Id == id);

            if (entity == null)
                return null;

            var oldEmail = entity.Email;
            var oldFirstName = entity.FirstName;
            var oldLastName = entity.LastName;
            var oldPhoneNumber = entity.PhoneNumber;
            var oldBirthDate = entity.BirthDate;
            var oldProfilePicture = entity.ProfilePicture;
            var oldIsDeleted = entity.IsDeleted;
            var oldPasswordHash = entity.PasswordHash;
            var oldPasswordSalt = entity.PasswordSalt;

            Mapper.Map(request, entity);

            if (string.IsNullOrWhiteSpace(request.FirstName))
                entity.FirstName = oldFirstName;

            if (string.IsNullOrWhiteSpace(request.LastName))
                entity.LastName = oldLastName;

            if (string.IsNullOrWhiteSpace(request.Email))
                entity.Email = oldEmail;

            if (string.IsNullOrWhiteSpace(request.PhoneNumber))
                entity.PhoneNumber = oldPhoneNumber;

            if (!request.BirthDate.HasValue)
                entity.BirthDate = oldBirthDate;

            if (!string.IsNullOrWhiteSpace(request.ProfilePicture))
                entity.ProfilePicture = Path.GetFileName(request.ProfilePicture);
            else
                entity.ProfilePicture = oldProfilePicture;

            if (!string.IsNullOrWhiteSpace(request.Password))
            {
                if (request.Password != request.PasswordConfirmation)
                    throw new UserException("Lozinka i potvrda lozinke moraju biti iste!");
                entity.PasswordSalt = GenerateSalt();
                entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
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
            }
            else
            {
                entity.IsDeleted = true;
            }

            await _context.SaveChangesAsync();
            return Mapper.Map<Users>(entity);
        }

        public static string GenerateSalt()
        {
            var byteArray = RandomNumberGenerator.GetBytes(16);
            return Convert.ToBase64String(byteArray);
        }

        public static string GenerateHash(string salt, string password)
        {
            byte[] src = Convert.FromBase64String(salt);
            byte[] bytes = Encoding.Unicode.GetBytes(password);
            byte[] dst = new byte[src.Length + bytes.Length];

            Buffer.BlockCopy(src, 0, dst, 0, src.Length);
            Buffer.BlockCopy(bytes, 0, dst, src.Length, bytes.Length);

            HashAlgorithm algorithm = HashAlgorithm.Create("SHA1");
            byte[] inArray = algorithm.ComputeHash(dst);
            return Convert.ToBase64String(inArray);
        }

        protected override async Task BeforeUpdate(User entity, UserUpdateRequest request)
        {
            await Task.CompletedTask;
        }

        public Users Login(string username, string password)
        {
            var entity = Context.Users.Include(x => x.UserRoles).ThenInclude(y => y.Role)
                .FirstOrDefault(x => x.Username == username);

            if (entity == null) return null;

            var hash = GenerateHash(entity.PasswordSalt, password);
            if (hash != entity.PasswordHash) return null;

            return Mapper.Map<Users>(entity);
        }

        public async Task<Users?> AuthenticateAsync(UserLoginRequest request)
        {
            if (string.IsNullOrEmpty(request.Username) || string.IsNullOrEmpty(request.Password))
                return null;

            var entity = await Context.Users
                .Include(x => x.UserRoles)
                .ThenInclude(y => y.Role)
                .FirstOrDefaultAsync(x => x.Username == request.Username);

            if (entity == null) return null;

            var hash = GenerateHash(entity.PasswordSalt, request.Password);
            if (hash != entity.PasswordHash) return null;

            return Mapper.Map<Users>(entity);
        }
    }
}