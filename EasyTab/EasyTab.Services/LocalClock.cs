namespace EasyTab.Services
{
    public static class LocalClock
    {
        // ReservationDate and StartTime/EndTime are venue-local wall time; system timestamps remain UTC.
        public static DateTime Now => TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, TimeZoneInfo.Local);
    }
}
