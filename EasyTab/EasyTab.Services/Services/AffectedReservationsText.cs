namespace EasyTab.Services.Services;

internal readonly record struct AffectedReservation(DateTime ReservationDate, TimeOnly StartTime, TimeOnly EndTime, string? TableName);

internal static class AffectedReservationsText
{
    private const int MaxListed = 5;

    // Navodi prvih pet termina, a ostale kao "i još N".
    public static string Describe(IReadOnlyList<AffectedReservation> reservations)
    {
        var listed = string.Join(", ", reservations.Take(MaxListed).Select(reservation =>
            $"{reservation.ReservationDate:dd.MM.yyyy} {reservation.StartTime:HH:mm}–{reservation.EndTime:HH:mm}" +
            (reservation.TableName == null ? string.Empty : $" ({reservation.TableName})")));
        var more = reservations.Count > MaxListed ? $" i još {reservations.Count - MaxListed}" : string.Empty;
        return listed + more;
    }
}
