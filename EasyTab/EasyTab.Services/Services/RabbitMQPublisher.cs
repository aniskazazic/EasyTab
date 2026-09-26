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
            var host = configuration["RabbitMQ:Host"] ?? "localhost";
            var username = configuration["RabbitMQ:Username"] ?? "admin";
            var password = configuration["RabbitMQ:Password"] ?? "admin";

            var connectionString = $"host={host};username={username};password={password}";
            _bus = RabbitHutch.CreateBus(connectionString);
        }

        public async Task PublishUserRegisteredAsync(UserRegisteredMessage message)
        {
            try
            {
                await _bus.PubSub.PublishAsync(message);
                _logger.LogInformation("Published UserRegisteredMessage for {Email}", message.Email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish UserRegisteredMessage for {Email}", message.Email);
            }
        }

        public async Task PublishReservationCreatedAsync(ReservationCreatedMessage message)
        {
            try
            {
                await _bus.PubSub.PublishAsync(message);
                _logger.LogInformation("Published ReservationCreatedMessage for ReservationId: {Id}", message.ReservationId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish ReservationCreatedMessage for ReservationId: {Id}", message.ReservationId);
            }
        }

        public async Task PublishReservationConfirmedAsync(ReservationConfirmedMessage message)
        {
            try
            {
                await _bus.PubSub.PublishAsync(message);
                _logger.LogInformation("Published ReservationConfirmedMessage for ReservationId: {Id}", message.ReservationId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish ReservationConfirmedMessage for ReservationId: {Id}", message.ReservationId);
            }
        }

        public async Task PublishReservationCancelledAsync(ReservationCancelledMessage message)
        {
            try
            {
                await _bus.PubSub.PublishAsync(message);
                _logger.LogInformation("Published ReservationCancelledMessage for ReservationId: {Id}", message.ReservationId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish ReservationCancelledMessage for ReservationId: {Id}", message.ReservationId);
            }
        }

        public async Task PublishPasswordResetAsync(PasswordResetMessage message)
        {
            try
            {
                await _bus.PubSub.PublishAsync(message);
                _logger.LogInformation("Published PasswordResetMessage for {Email}", message.Email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to publish PasswordResetMessage for {Email}", message.Email);
            }
        }

        public void Dispose()
        {
            _bus?.Dispose();
        }
    }
}
