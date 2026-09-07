using EasyNetQ;
using EasyTab.Model.Messages;
using EasyTab.Subscriber.Consumers;

namespace EasyTab.Subscriber
{
    public class RabbitMQWorker : BackgroundService
    {
        private readonly ILogger<RabbitMQWorker> _logger;
        private readonly IConfiguration _configuration;
        private readonly IServiceProvider _serviceProvider;
        private IBus? _bus;

        public RabbitMQWorker(ILogger<RabbitMQWorker> logger, IConfiguration configuration, IServiceProvider serviceProvider)
        {
            _logger = logger;
            _configuration = configuration;
            _serviceProvider = serviceProvider;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var host = _configuration["RabbitMQ:Host"] ?? "localhost";
            var username = _configuration["RabbitMQ:Username"] ?? "admin";
            var password = _configuration["RabbitMQ:Password"] ?? "admin";

            var connectionString = $"host={host};username={username};password={password}";

            _logger.LogInformation("Connecting to RabbitMQ at {Host}...", host);

            // Retry logika za slučaj da RabbitMQ nije spreman odmah
            var retries = 0;
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    _bus = RabbitHutch.CreateBus(connectionString);
                    _logger.LogInformation("Connected to RabbitMQ. Setting up consumers...");
                    break;
                }
                catch (Exception ex)
                {
                    retries++;
                    _logger.LogWarning("Failed to connect to RabbitMQ (attempt {Retry}): {Message}", retries, ex.Message);
                    if (retries >= 10) throw;
                    await Task.Delay(5000, stoppingToken);
                }
            }

            if (_bus == null) return;

            // Subscribe na UserRegisteredMessage
            await _bus.PubSub.SubscribeAsync<UserRegisteredMessage>(
                "easytab-subscriber-user-registered",
                async msg =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    var consumer = scope.ServiceProvider.GetRequiredService<UserRegisteredConsumer>();
                    await consumer.HandleAsync(msg);
                },
                stoppingToken);

            _logger.LogInformation("Subscribed to UserRegisteredMessage");

            // Subscribe na ReservationCreatedMessage
            await _bus.PubSub.SubscribeAsync<ReservationCreatedMessage>(
                "easytab-subscriber-reservation-created",
                async msg =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    var consumer = scope.ServiceProvider.GetRequiredService<ReservationCreatedConsumer>();
                    await consumer.HandleAsync(msg);
                },
                stoppingToken);

            _logger.LogInformation("Subscribed to ReservationCreatedMessage");

            // Subscribe na ReservationConfirmedMessage
            await _bus.PubSub.SubscribeAsync<ReservationConfirmedMessage>(
                "easytab-subscriber-reservation-confirmed",
                async msg =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    var consumer = scope.ServiceProvider.GetRequiredService<ReservationConfirmedConsumer>();
                    await consumer.HandleAsync(msg);
                },
                stoppingToken);

            _logger.LogInformation("Subscribed to ReservationConfirmedMessage");

            // Subscribe na ReservationCancelledMessage
            await _bus.PubSub.SubscribeAsync<ReservationCancelledMessage>(
                "easytab-subscriber-reservation-cancelled",
                async msg =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    var consumer = scope.ServiceProvider.GetRequiredService<ReservationCancelledConsumer>();
                    await consumer.HandleAsync(msg);
                },
                stoppingToken);

            _logger.LogInformation("Subscribed to ReservationCancelledMessage");
            _logger.LogInformation("EasyTab Subscriber is running and waiting for messages...");

            // Drži worker aktivan dok se ne zaustavi
            await Task.Delay(Timeout.Infinite, stoppingToken);
        }

        public override void Dispose()
        {
            _bus?.Dispose();
            base.Dispose();
        }
    }
}
