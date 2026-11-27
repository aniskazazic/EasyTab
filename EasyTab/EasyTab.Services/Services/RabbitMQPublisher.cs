using System.Threading.Channels;
using EasyTab.Model.Messages;
using EasyTab.Services.Interfaces;
using Microsoft.Extensions.Logging;

namespace EasyTab.Services.Services
{
    // Poruka čeka u redu dok je RabbitMQPublisherBackgroundService ne objavi.
    public sealed record QueuedRabbitMQMessage(object Message, Type MessageType, string Description);

    public class RabbitMQPublisher : IRabbitMQPublisher
    {
        private const int QueueCapacity = 1000;

        private readonly ChannelWriter<QueuedRabbitMQMessage> _queue;
        private readonly ILogger<RabbitMQPublisher> _logger;

        public RabbitMQPublisher(Channel<QueuedRabbitMQMessage> queue, ILogger<RabbitMQPublisher> logger)
        {
            _queue = queue.Writer;
            _logger = logger;
        }

        // Ograničen red: kada je pun, upis čeka slobodno mjesto, pa se poruka ne gubi.
        public static Channel<QueuedRabbitMQMessage> CreateQueue() =>
            Channel.CreateBounded<QueuedRabbitMQMessage>(new BoundedChannelOptions(QueueCapacity)
            {
                SingleReader = true,
                FullMode = BoundedChannelFullMode.Wait
            });

        public Task PublishUserRegisteredAsync(UserRegisteredMessage message) =>
            EnqueueAsync(message, $"UserRegisteredMessage for {message.Email}");

        public Task PublishReservationCreatedAsync(ReservationCreatedMessage message) =>
            EnqueueAsync(message, $"ReservationCreatedMessage for ReservationId: {message.ReservationId}");

        public Task PublishReservationConfirmedAsync(ReservationConfirmedMessage message) =>
            EnqueueAsync(message, $"ReservationConfirmedMessage for ReservationId: {message.ReservationId}");

        public Task PublishReservationCancelledAsync(ReservationCancelledMessage message) =>
            EnqueueAsync(message, $"ReservationCancelledMessage for ReservationId: {message.ReservationId}");

        public Task PublishPasswordResetAsync(PasswordResetMessage message) =>
            EnqueueAsync(message, $"PasswordResetMessage for {message.Email}");

        private async Task EnqueueAsync<T>(T message, string description) where T : class
        {
            try
            {
                await _queue.WriteAsync(new QueuedRabbitMQMessage(message, typeof(T), description));
            }
            catch (ChannelClosedException)
            {
                // Red se zatvara samo pri gašenju aplikacije; poslovna promjena je već spremljena, pa se zahtjev ne obara.
                _logger.LogError("Failed to queue {Description} because the application is shutting down", description);
            }
        }
    }
}
