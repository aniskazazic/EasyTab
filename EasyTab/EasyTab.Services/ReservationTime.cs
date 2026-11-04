namespace EasyTab.Services;

public static class ReservationTime
{
    public static DateTime GetStart(DateTime reservationDate, TimeOnly startTime)
        => GetStart(reservationDate, startTime.ToTimeSpan());

    public static DateTime GetStart(DateTime reservationDate, TimeSpan startTime)
        => reservationDate.Date.Add(startTime);
}
