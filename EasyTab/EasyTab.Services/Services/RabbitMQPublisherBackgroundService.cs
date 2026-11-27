using System.Threading.Channels;
using EasyNetQ;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace EasyTab.Services.Services
{
    // Jedini objavljivač prema RabbitMQ-u: drži jednu konekciju (IBus) i objavljuje poruke iz reda koji puni RabbitMQPublisher.
    public sealed class RabbitMQPublisherBackgroundService : BackgroundService
    {
        private const int MaxPublishAttempts = 5;

        // Pri gašenju se poruke iz reda objavljuju najduže ovoliko, što je kraće od Docker roka za gašenje (10 s).
        private static readonly TimeSpan DrainTimeout = TimeSpan.FromSeconds(5);

        private readonly Channel<QueuedRabbitMQMessage> _queue;
        private readonly ILogger<RabbitMQPublisherBackgroundService> _logger;
        private readonly IBus _bus;

        public RabbitMQPublisherBackgroundService(
            IConfiguration configuration,
            Channel<QueuedRabbitMQMessage> queue,
            ILogger<RabbitMQPublisherBackgroundService> logger)
        {
            _queue = queue;
            _logger = logger;
            var host = RequireSetting(configuration, "RabbitMQ:Host");
            var port = int.Parse(RequireSetting(configuration, "RabbitMQ:Port"));
            var username = RequireSetting(configuration, "RabbitMQ:Username");
            var password = RequireSetting(configuration, "RabbitMQ:Password");

            var connectionString = $"host={host};port={port};username={username};password={password}";
            _bus = RabbitHutch.CreateBus(connectionString);
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            using var drain = new CancellationTokenSource();
            // Na signal gašenja red više ne prima nove poruke, a već upisane se objavljuju do isteka DrainTimeout.
            using var stopping = stoppingToken.Register(() =>
            {
                _queue.Writer.TryComplete();
                drain.CancelAfter(DrainTimeout);
            });

            QueuedRabbitMQMessage? current = null;
            try
            {
                await foreach (var message in _queue.Reader.ReadAllAsync(drain.Token))
                {
                    current = message;
                    await PublishWithRetryAsync(message, drain.Token);
                    current = null;
                }
            }
            catch (Exception ex) when (drain.IsCancellationRequested)
            {
                _logger.LogError(
                    ex,
                    "Publishing stopped {DrainSeconds}s after shutdown started. Not published: {Current} and {QueuedCount} queued messages",
                    DrainTimeout.TotalSeconds,
                    current?.Description ?? "none",
                    _queue.Reader.Count);
            }
        }

        private async Task PublishWithRetryAsync(QueuedRabbitMQMessage message, CancellationToken cancellationToken)
        {
            for (var attempt = 0; attempt < MaxPublishAttempts; attempt++)
            {
                try
                {
                    await _bus.PubSub.PublishAsync(message.Message, message.MessageType, cancellationToken);
                    _logger.LogInformation("Published {Description}", message.Description);
                    return;
                }
                catch (Exception ex) when (attempt < MaxPublishAttempts - 1 && !cancellationToken.IsCancellationRequested)
                {
                    var delaySeconds = 1 << attempt;
                    _logger.LogWarning(
                        ex,
                        "Failed to publish {Description}. Retrying in {DelaySeconds}s (attempt {Attempt}/{MaxAttempts})",
                        message.Description,
                        delaySeconds,
                        attempt + 1,
                        MaxPublishAttempts);
                    await Task.Delay(TimeSpan.FromSeconds(delaySeconds), cancellationToken);
                }
                catch (Exception ex) when (!cancellationToken.IsCancellationRequested)
                {
                    _logger.LogError(ex, "Failed to publish {Description} after {MaxAttempts} attempts", message.Description, MaxPublishAttempts);
                }
            }
        }

        private static string RequireSetting(IConfiguration configuration, string key)
        {
            var value = configuration[key];
            if (string.IsNullOrWhiteSpace(value))
                throw new InvalidOperationException($"Nedostaje obavezna konfiguracijska vrijednost '{key}'.");

            return value;
        }

        public override void Dispose()
        {
            _bus.Dispose();
            base.Dispose();
        }
    }
}
