using EasyTab.Model.Messages;

namespace EasyTab.Services.Interfaces
{
    public interface IRabbitMQPublisher
    {
        Task PublishUserRegisteredAsync(UserRegisteredMessage message);
        Task PublishReservationCreatedAsync(ReservationCreatedMessage message);
        Task PublishReservationCancelledAsync(ReservationCancelledMessage message);
    }
}
