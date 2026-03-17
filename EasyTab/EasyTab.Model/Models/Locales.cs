using System;
using System.Collections.Generic;
using System.Text;

namespace EasyTab.Model.Models
{
    public class Locales
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Address { get; set; }
        public TimeOnly StartOfWorkingHours { get; set; }
        public TimeOnly EndOfWorkingHours { get; set; }
        public double? LengthOfReservation { get; set; }
        public string? Logo { get; set; }
        public string? PhoneNumber { get; set; }
        public int CityId { get; set; }
        public string? CityName { get; set; }
        public int CategoryId { get; set; }
        public string? CategoryName { get; set; }
        public int OwnerId { get; set; }
        public bool IsDeleted { get; set; }
        public string? CountryName { get; set; }
        public string? OwnerName { get; set; }
    }
}
