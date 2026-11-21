using EasyTab.Model.Exceptions;

namespace EasyTab.Services;

public static class ReservationTime
{
    private static readonly DateTime MinSupportedDate = new(2000, 1, 1);
    private static readonly DateTime MaxSupportedDate = new(2100, 12, 31);

        public static void EnsureSupportedDate(DateTime date)
    {
        if (date.Date < MinSupportedDate || date.Date > MaxSupportedDate)
            throw new UserException($"Datum mora biti između {MinSupportedDate:dd.MM.yyyy}. i {MaxSupportedDate:dd.MM.yyyy}.");
    }

    public static DateTime GetStart(DateTime reservationDate, TimeOnly startTime)
        => GetStart(reservationDate, startTime.ToTimeSpan());

    public static DateTime GetStart(DateTime reservationDate, TimeSpan startTime)
        => DateTime.SpecifyKind(reservationDate.Date, DateTimeKind.Unspecified).Add(startTime);

    public static DateTime GetEnd(DateTime reservationDate, TimeOnly startTime, TimeOnly endTime)
        => GetStart(reservationDate, endTime).AddDays(endTime < startTime ? 1 : 0);

    public static bool HasStarted(DateTime reservationDate, TimeOnly startTime)
        => GetStart(reservationDate, startTime) <= LocalClock.Now;

    public static DateTime GetWorkingDate(DateTime reservationDate, TimeOnly startTime,
        TimeOnly openingTime, TimeOnly closingTime)
        => reservationDate.Date.AddDays(closingTime < openingTime && startTime < openingTime ? -1 : 0);

    public static bool IsWithinWorkingHours(DateTime reservationDate, TimeOnly startTime, TimeOnly endTime,
        TimeOnly openingTime, TimeOnly closingTime)
    {
        var workingDate = GetWorkingDate(reservationDate, startTime, openingTime, closingTime);
        return GetStart(workingDate, openingTime) <= GetStart(reservationDate, startTime) &&
               GetEnd(reservationDate, startTime, endTime) <= GetEnd(workingDate, openingTime, closingTime);
    }
}
