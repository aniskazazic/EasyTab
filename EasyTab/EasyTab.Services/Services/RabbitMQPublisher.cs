using EasyNetQ;
using EasyTab.Model.Messages;
using EasyTab.Services.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace EasyTab.Services.Services
{
    public class RabbitMQPublisher : IRabbitMQPublisher, IDisposable
    {
        private readonly IBus _bus;
        private readonly ILogger<RabbitMQPublisher> _logger;

        public RabbitMQPublisher(IConfiguration configuration, ILogger<RabbitMQPublisher> logger)
        {
            _logger = logger;
            var host = RequireSetting(configuration, "RabbitMQ:Host");
            var username = RequireSetting(configuration, "RabbitMQ:Username");
            var password = RequireSetting(configuration, "RabbitMQ:Password");

            var connectionString = $"host={host};username={username};password={password}";
            _bus = RabbitHutch.CreateBus(connectionString);
        }

        public Task PublishUserRegisteredAsync(UserRegisteredMessage message)
        {
            QueuePublish(message, $"UserRegisteredMessage for {message.Email}");
            return Task.CompletedTask;
        }

        public Task PublishReservationCreatedAsync(ReservationCreatedMessage message)
        {
            QueuePublish(message, $"ReservationCreatedMessage for ReservationId: {message.ReservationId}");
            return Task.CompletedTask;
        }

        public Task PublishReservationConfirmedAsync(ReservationConfirmedMessage message)
        {
            QueuePublish(message, $"ReservationConfirmedMessage for ReservationId: {message.ReservationId}");
            return Task.CompletedTask;
        }

        public Task PublishReservationCancelledAsync(ReservationCancelledMessage message)
        {
            QueuePublish(message, $"ReservationCancelledMessage for ReservationId: {message.ReservationId}");
            return Task.CompletedTask;
        }

        public Task PublishPasswordResetAsync(PasswordResetMessage message)
        {
            QueuePublish(message, $"PasswordResetMessage for {message.Email}");
            return Task.CompletedTask;
        }

        private void QueuePublish<T>(T message, string description)
        {
            _ = PublishWithRetryAsync(message, description);
        }

        private async Task PublishWithRetryAsync<T>(T message, string description)
        {
            for (var attempt = 0; attempt < 5; attempt++)
            {
                try
                {
                    await _bus.PubSub.PublishAsync(message);
                    _logger.LogInformation("Published {Description}", description);
                    return;
                }
                catch (Exception ex) when (attempt < 4)
                {
                    var delaySeconds = 1 << attempt;
                    _logger.LogWarning(
                        ex,
                        "Failed to publish {Description}. Retrying in {DelaySeconds}s (attempt {Attempt}/5)",
                        description,
                        delaySeconds,
                        attempt + 1);
                    await Task.Delay(TimeSpan.FromSeconds(delaySeconds));
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to publish {Description} after 5 attempts", description);
                }
            }
        }

        private static string RequireSetting(IConfiguration configuration, string key)
        {
            var value = configuration[key];
            if (string.IsNullOrWhiteSpace(value))
                throw new InvalidOperationException($"Missing required configuration value '{key}'.");

            return value;
        }

        public void Dispose()
        {
            _bus.Dispose();
        }
    }
}
