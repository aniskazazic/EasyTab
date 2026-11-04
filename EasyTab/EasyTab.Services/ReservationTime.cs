namespace EasyTab.Services;

public static class ReservationTime
{
    public static DateTime GetStart(DateTime reservationDate, TimeOnly startTime)
        => GetStart(reservationDate, startTime.ToTimeSpan());

    public static DateTime GetStart(DateTime reservationDate, TimeSpan startTime)
        => DateTime.SpecifyKind(reservationDate.Date, DateTimeKind.Unspecified).Add(startTime);

    public static DateTime GetEnd(DateTime reservationDate, TimeOnly startTime, TimeOnly endTime)
        => GetStart(reservationDate, endTime).AddDays(endTime < startTime ? 1 : 0);

    public static DateTime GetWorkingDate(DateTime reservationDate, TimeOnly startTime,
        TimeOnly openingTime, TimeOnly closingTime)
        => reservationDate.Date.AddDays(closingTime < openingTime && startTime < openingTime ? -1 : 0);
}
