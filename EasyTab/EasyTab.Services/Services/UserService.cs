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

namespace EasyTab.Services.Services
{
    public class UserService : BaseCRUDService<Users, UserSearchObject, User, UserInsertRequest, UserUpdateRequest>, IUserService
    {
        ILogger<IUserService> _logger;
        public UserService(_220030Context context, IMapper mapper, ILogger<IUserService> logger) : base(context, mapper)
        {
            _logger = logger;
        }

        public override IQueryable<User> AddFilter(IQueryable<User> query, UserSearchObject searchObject)
        {
            query = base.AddFilter(query, searchObject);

            if (!string.IsNullOrEmpty(searchObject?.FirstNameGTE))
                query = query.Where(x => x.FirstName.StartsWith(searchObject.FirstNameGTE));

            if (!string.IsNullOrEmpty(searchObject?.LastNameGTE))
                query = query.Where(x => x.LastName.StartsWith(searchObject.LastNameGTE));

            if (!string.IsNullOrEmpty(searchObject?.Username))
                query = query.Where(x => x.Username == searchObject.Username);

            if (!string.IsNullOrEmpty(searchObject?.Email))
                query = query.Where(x => x.Email == searchObject.Email);

            return query;
        }

        public override void BeforeInsert(UserInsertRequest request, User entity)
        {
            _logger.LogInformation("Inserting user with username: {Username}", request.Username);
            if (request.Password != request.PasswordConfirmation)
                throw new UserException("Lozinka i potvrda lozinke moraju biti iste !");

            entity.PasswordSalt = GenerateSalt();
            entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);

            base.BeforeInsert(request, entity);
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

        public override void BeforeUpdate(UserUpdateRequest request, User entity)
        {
            base.BeforeUpdate(request, entity);
            if (request.Password != null)
            {
                if (request.Password != request.PasswordConfirmation)
                    throw new Exception("Lozinka i potvrda lozinke moraju biti iste !");

                entity.PasswordSalt = GenerateSalt();
                entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
            }

            
        }
    }
}
