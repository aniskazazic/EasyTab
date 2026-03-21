using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Models
{
    public class Workers
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Username { get; set; }
        public string? Email { get; set; }
        public string? PhoneNumber { get; set; }
        public DateTime? HireDate { get; set; }
        public DateTime? EndDate { get; set; }
        public DateTime? BirthDate {  get; set; }
        public int LocaleId { get; set; }
        public string? LocaleName { get; set; }
        public string? ProfilePicture { get; set; }
    }
}
