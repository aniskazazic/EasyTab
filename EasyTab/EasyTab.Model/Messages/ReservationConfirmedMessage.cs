using System;

namespace EasyTab.Model.Messages
{
    public class ReservationConfirmedMessage
    {
        public int ReservationId { get; set; }
        public int UserId { get; set; }
        public string UserEmail { get; set; } = string.Empty;
        public string UserFullName { get; set; } = string.Empty;
        public string LocaleName { get; set; } = string.Empty;
        public DateTime ReservationDate { get; set; }
        public string StartTime { get; set; } = string.Empty;
        public string EndTime { get; set; } = string.Empty;
        public int NumberOfGuests { get; set; }
    }
}
