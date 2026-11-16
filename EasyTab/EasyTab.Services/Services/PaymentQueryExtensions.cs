using EasyTab.Services.Database;

namespace EasyTab.Services.Services;

internal static class PaymentQueryExtensions
{
    // Aktivan pokušaj plaćanja: checkout bez rezervacije kojem nije istekao rok PayPal__CheckoutHoldMinutes.
    // Istekli pokušaj ostaje u bazi kao finansijska evidencija, ali više ne drži ni termin ni stol.
    public static IQueryable<Payment> ActiveCheckouts(this IQueryable<Payment> payments, int holdMinutes)
    {
        var holdCutoff = DateTime.UtcNow.AddMinutes(-holdMinutes);
        return payments.Where(payment =>
            payment.Status == PaymentStatus.Created &&
            payment.CheckoutId != null &&
            payment.ReservationId == null &&
            payment.CreatedAt > holdCutoff);
    }
}
