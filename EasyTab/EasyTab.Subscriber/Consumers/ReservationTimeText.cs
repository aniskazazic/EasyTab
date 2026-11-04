using System.Globalization;

namespace EasyTab.Subscriber.Consumers;

internal static class ReservationTimeText
{
    public static string Format(string start, string end)
    {
        if (string.IsNullOrEmpty(end))
            return start;

        var nextDay = TimeOnly.TryParseExact(start, "HH:mm", CultureInfo.InvariantCulture,
                DateTimeStyles.None, out var startTime) &&
            TimeOnly.TryParseExact(end, "HH:mm", CultureInfo.InvariantCulture,
                DateTimeStyles.None, out var endTime) && endTime < startTime;
        return $"{start} - {end}{(nextDay ? " (sljedeći dan)" : string.Empty)}";
    }
}
