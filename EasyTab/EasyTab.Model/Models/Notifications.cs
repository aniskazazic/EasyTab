using System;
using System.Text.Json.Serialization;
using EasyTab.Model.Serialization;

namespace EasyTab.Model.Models
{
    public class Notifications
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public bool IsRead { get; set; }
        [JsonConverter(typeof(UtcDateTimeJsonConverter))]
        public DateTime CreatedAt { get; set; }
    }
}
