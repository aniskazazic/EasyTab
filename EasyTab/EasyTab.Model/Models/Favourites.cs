using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.Json.Serialization;
using EasyTab.Model.Serialization;

namespace EasyTab.Model.Models
{
    public class Favourites
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int LocaleId { get; set; }
        public string? LocaleName { get; set; }
        public string? LocaleAddress { get; set; }
        public string? LocaleLogo { get; set; }
        public string? LocaleCategoryName { get; set; }
        public string? LocaleCityName { get; set; }
        public TimeOnly StartOfWorkingHours { get; set; }
        public TimeOnly EndOfWorkingHours { get; set; }
        [JsonConverter(typeof(UtcDateTimeJsonConverter))]
        public DateTime DateAdded { get; set; }
        public bool IsActive { get; set; }
    }
}
