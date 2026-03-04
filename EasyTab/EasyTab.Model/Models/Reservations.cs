using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Model.Models
{
    public class Reservations
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public int TableId { get; set; }
        public string? TableName { get; set; }
        public int? NumberOfGuests { get; set; }
        public DateTime ReservationDate { get; set; }
        public TimeSpan StartTime { get; set; }
        public TimeSpan EndTime { get; set; }
        public DateTime CreatedAt { get; set; }
        public bool IsCancelled { get; set; }
        public int? LocaleId { get; set; }
        public string? LocaleName { get; set; }
        public string? LocaleAddress { get; set; }
        public string? LocaleLogo { get; set; }
    }
}
