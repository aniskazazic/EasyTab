using System.Linq.Expressions;
using EasyTab.Services.Database;
using EasyTab.Services.ReservationStateMachine;

namespace EasyTab.Services.Services;

internal static class ReservationQueryExtensions
{
    // Otvorena rezervacija: nije otkazana ni završena i termin još nije završio (uključujući termin u toku).
    // Kraj termina je dan rezervacije, a sljedeći dan ako termin prelazi ponoć (EndTime < StartTime).
    private static Expression<Func<Reservation, bool>> IsOpen(DateTime now)
    {
        var today = now.Date;
        var nowTime = TimeOnly.FromDateTime(now);
        return reservation =>
            reservation.ReservationState != CancelledReservationState.StateName &&
            reservation.ReservationState != CompletedReservationState.StateName &&
            (reservation.ReservationDate.Date.AddDays(reservation.EndTime < reservation.StartTime ? 1 : 0) > today ||
             (reservation.ReservationDate.Date.AddDays(reservation.EndTime < reservation.StartTime ? 1 : 0) == today &&
              reservation.EndTime > nowTime));
    }

    public static IQueryable<Reservation> Open(this IQueryable<Reservation> reservations, DateTime now)
        => reservations.Where(IsOpen(now));

    // Historija je tačna negacija otvorenih, pa je svaka rezervacija uvijek na tačno jednoj listi.
    public static IQueryable<Reservation> Closed(this IQueryable<Reservation> reservations, DateTime now)
    {
        var isOpen = IsOpen(now);
        return reservations.Where(
            Expression.Lambda<Func<Reservation, bool>>(Expression.Not(isOpen.Body), isOpen.Parameters));
    }
}
