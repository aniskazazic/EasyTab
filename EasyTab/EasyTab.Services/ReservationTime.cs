namespace EasyTab.Services;

public static class ReservationTime
{
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

    // Termin je unutar radnog vremena ako je cijeli u prozoru svog radnog dana, kao u ponudi termina.
    public static bool IsWithinWorkingHours(DateTime reservationDate, TimeOnly startTime, TimeOnly endTime,
        TimeOnly openingTime, TimeOnly closingTime)
    {
        var workingDate = GetWorkingDate(reservationDate, startTime, openingTime, closingTime);
        return GetStart(workingDate, openingTime) <= GetStart(reservationDate, startTime) &&
               GetEnd(reservationDate, startTime, endTime) <= GetEnd(workingDate, openingTime, closingTime);
    }
}
