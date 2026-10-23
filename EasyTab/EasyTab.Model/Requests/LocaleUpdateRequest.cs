using System;
using System.Collections.Generic;
using System.Text.Json.Serialization;
using EasyTab.Model.Serialization;

namespace EasyTab.Model.Requests
{
    public class LocaleUpdateRequest
    {
        public string? Name { get; set; }
        public string? Address { get; set; }
        public TimeOnly? StartOfWorkingHours { get; set; }
        public TimeOnly? EndOfWorkingHours { get; set; }
        [JsonConverter(typeof(NullableReservationDurationJsonConverter))]
        public double? LengthOfReservation { get; set; }
        public string? Logo { get; set; }
        public string? PhoneNumber { get; set; }
        public int? CityId { get; set; }
        public int? CategoryId { get; set; }
        public bool? IsDeleted { get; set; }
        public decimal? ReservationPrice { get; set; }
        public List<LocaleImageInsertRequest>? Images { get; set; }

    }
}
