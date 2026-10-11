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
            var host = RequireSetting("RabbitMQ:Host");
            var username = RequireSetting("RabbitMQ:Username");
            var password = RequireSetting("RabbitMQ:Password");
            var connectionString = $"host={host};username={username};password={password}";

            _logger.LogInformation("Connecting to RabbitMQ at {Host}...", host);

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
                    _logger.LogWarning(ex, "Failed to connect to RabbitMQ (attempt {Retry}): {Message}", retries, ex.Message);
                    if (retries >= 10) throw;
                    await Task.Delay(5000, stoppingToken);
                }
            }

            if (_bus == null) return;

            await _bus.PubSub.SubscribeAsync<UserRegisteredMessage>(
                "easytab-subscriber-user-registered",
                async msg =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    await scope.ServiceProvider.GetRequiredService<UserRegisteredConsumer>().HandleAsync(msg);
                },
                stoppingToken);

            await _bus.PubSub.SubscribeAsync<ReservationCreatedMessage>(
                "easytab-subscriber-reservation-created",
                async msg =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    await scope.ServiceProvider.GetRequiredService<ReservationCreatedConsumer>().HandleAsync(msg);
                },
                stoppingToken);

            await _bus.PubSub.SubscribeAsync<ReservationConfirmedMessage>(
                "easytab-subscriber-reservation-confirmed",
                async msg =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    await scope.ServiceProvider.GetRequiredService<ReservationConfirmedConsumer>().HandleAsync(msg);
                },
                stoppingToken);

            await _bus.PubSub.SubscribeAsync<ReservationCancelledMessage>(
                "easytab-subscriber-reservation-cancelled",
                async msg =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    await scope.ServiceProvider.GetRequiredService<ReservationCancelledConsumer>().HandleAsync(msg);
                },
                stoppingToken);

            await _bus.PubSub.SubscribeAsync<PasswordResetMessage>(
                "easytab-subscriber-password-reset",
                async msg =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    await scope.ServiceProvider.GetRequiredService<PasswordResetConsumer>().HandleAsync(msg);
                },
                stoppingToken);

            _logger.LogInformation("EasyTab Subscriber is running and waiting for messages...");
            await Task.Delay(Timeout.Infinite, stoppingToken);
        }

        private string RequireSetting(string key)
        {
            var value = _configuration[key];
            if (string.IsNullOrWhiteSpace(value))
                throw new InvalidOperationException($"Missing required configuration value '{key}'.");

            return value;
        }

        public override void Dispose()
        {
            _bus?.Dispose();
            base.Dispose();
        }
    }
}
