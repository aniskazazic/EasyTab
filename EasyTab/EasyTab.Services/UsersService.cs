using EasyTab.Model;
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

namespace EasyTab.Services
{
    public class UsersService : IUsersService
    {
        public _220030Context Context { get; set; }
        public IMapper Mapper { get; set; }
        public UsersService(_220030Context context, IMapper mapper)
        {
            Context = context;
            Mapper = mapper;
        }
        public virtual List<Users> GetUsers()
        {
            List<Users> result = new List<Users>();

            var list = Context.Users.ToList();

            //list.ForEach(item =>
            //{
            //    result.Add(new Users()
            //    {
            //        FirstName = item.FirstName,
            //        LastName = item.LastName,
            //        Email = item.Email,
            //        Id = item.Id,
            //        PhoneNumber = item.PhoneNumber,
            //        ProfilePicture = item.ProfilePicture,
            //        BirthDate = item.BirthDate,
            //        Username = item.Username
            //    });
            //});

            result = Mapper.Map(list, result);

            return result;
        }

        public Users Insert(UserInsertRequest request)
        {
            if (request.Password != request.PasswordConfirmation)
                throw new Exception("Lozinka i potvrda lozinke moraju biti iste !");

            User entity = new User();  
            Mapper.Map(request, entity);

            entity.PasswordSalt = GenerateSalt();
            entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);

            Context.Add(entity);
            Context.SaveChanges();

            return Mapper.Map<Users>(entity);
        }

        public static string GenerateSalt()
        {
            var byteArray = RNGCryptoServiceProvider.GetBytes(16);
            return Convert.ToBase64String(byteArray);
        }

        public static string GenerateHash(string salt, string password)
        {
            byte[] src = Convert.FromBase64String(salt);
            byte[] bytes = Encoding.Unicode.GetBytes(password);
            byte[] dst = new byte[src.Length + bytes.Length];

            System.Buffer.BlockCopy(src, 0, dst, 0, src.Length);
            System.Buffer.BlockCopy(bytes, 0, dst, src.Length, bytes.Length);

            HashAlgorithm algorithm = HashAlgorithm.Create("SHA1");
            byte[] inArray = algorithm.ComputeHash(dst);
            return Convert.ToBase64String(inArray);
        }

        public Users Update(int id, UserUpdateRequest request)
        {
            var entity = Context.Users.Find(id);

            Mapper.Map(request, entity);

            if (request.Password != null)
            {
                if (request.Password != request.PasswordConfirmation)
                    throw new Exception("Lozinka i potvrda lozinke moraju biti iste !");

                entity.PasswordSalt = GenerateSalt();
                entity.PasswordHash = GenerateHash(entity.PasswordSalt, request.Password);
            }

            Context.SaveChanges();
            return Mapper.Map<Users>(entity);
        }
    }
}
