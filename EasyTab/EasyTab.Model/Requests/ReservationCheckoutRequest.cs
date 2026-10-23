using System;

namespace EasyTab.Model.Requests;

public sealed class ReservationCheckoutRequest : ReservationInsertRequest
{
    public Guid CheckoutId { get; set; }
}
