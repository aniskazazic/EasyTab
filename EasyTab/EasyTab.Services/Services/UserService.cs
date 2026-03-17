using EasyTab.Model;
using EasyTab.Model.SearchObject;
using EasyTab.Model.Requests;
using EasyTab.Services.Database;
using MapsterMapper;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Interfaces;
using Microsoft.Extensions.Logging;
using EasyTab.Model.Models;

namespace EasyTab.Services.Services
{
    public class UserService : BaseCRUDService<Users, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        ILogger<IUserService> _logger;
        public UserService(_220030Context context, IMapper mapper, ILogger<IUserService> logger) : base(context, mapper)
        {
            _logger = logger;
        }

        protected override IQueryable<User> ApplyFilter(IQueryable<User> query, UserSearchObject searchObject)
        {
            query = query.Include(x => x.UserRoles)
                 .ThenInclude(y => y.Role);

            // NE filtriramo IsDeleted automatski — šaljemo sve
            if (!string.IsNullOrEmpty(searchObject?.FirstNameGTE))
                query = query.Where(x => x.FirstName.StartsWith(searchObject.FirstNameGTE));

            if (!string.IsNullOrEmpty(searchObject?.LastNameGTE))
                query = query.Where(x => x.LastName.StartsWith(searchObject.LastNameGTE));

            if (!string.IsNullOrEmpty(searchObject?.Username))
                query = query.Where(x => x.Username == searchObject.Username);

            if (!string.IsNullOrEmpty(searchObject?.Email))
                query = query.Where(x => x.Email == searchObject.Email);

            // FTS pretraga
            if (!string.IsNullOrEmpty(searchObject?.FTS))
                query = query.Where(x =>
                    x.FirstName.Contains(searchObject.FTS) ||
                    x.LastName.Contains(searchObject.FTS) ||
                    x.Email.Contains(searchObject.FTS) ||
                    x.Username.Contains(searchObject.FTS));

            // Samo ako eksplicitno tražimo filtriraj po IsDeleted
            if (searchObject?.IsDeleted == true)
                query = query.Where(x => x.IsDeleted == searchObject.IsDeleted);

            return query;
        }

        public override async Task<Users> CreateAsync(UserInsertRequest request)
        {
            var result = await base.CreateAsync(request);

            // Dodaj role ako su proslijeđene
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

            // Provjeri duplikate
            if (await Context.Users.AnyAsync(u => u.Email == request.Email))
                throw new UserException("Korisnik sa ovim emailom već postoji!");

            if (await Context.Users.AnyAsync(u => u.Username == request.Username))
                throw new UserException("Korisnik sa ovim korisničkim imenom već postoji!");

            entity.PasswordSalt = GenerateSalt();
            entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
            entity.IsDeleted = false;

            await Task.CompletedTask;
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
            if (request.Password != null)
            {
                if (request.Password != request.PasswordConfirmation)
                    throw new Exception("Lozinka i potvrda lozinke moraju biti iste!");

                entity.PasswordSalt = GenerateSalt();
                entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
            }

            await Task.CompletedTask;
        }

        public Users Login(string username, string password)
        {
            var entity = Context.Users.Include(x=>x.UserRoles).ThenInclude(y => y.Role).FirstOrDefault(x=>x.Username == username);

            if (entity == null)
            {
                return null;
            }
            var hash = GenerateHash(entity.PasswordSalt, password);

            if (hash != entity.PasswordHash)
            {
                return null;
            }
            else
            {
                return Mapper.Map<Users>(entity);
            }

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
