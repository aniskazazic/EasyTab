using EasyTab.Subscriber;
using EasyTab.Subscriber.Consumers;
using EasyTab.Subscriber.Services;

var host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) =>
    {
        // Email servis
        services.AddScoped<EmailService>();

        // Consumers
        services.AddScoped<UserRegisteredConsumer>();
        services.AddScoped<ReservationCreatedConsumer>();
        services.AddScoped<ReservationCancelledConsumer>();

        // Worker
        services.AddHostedService<RabbitMQWorker>();
    })
    .Build();

await host.RunAsync();
