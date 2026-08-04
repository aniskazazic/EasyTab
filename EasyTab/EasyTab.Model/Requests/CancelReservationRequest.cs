namespace EasyTab.Model.Requests
{
    public class CancelReservationRequest
    {
        public string Reason { get; set; } = string.Empty;
        public int CancelledById { get; set; }
    }
}
