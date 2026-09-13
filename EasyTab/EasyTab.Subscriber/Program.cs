using EasyTab.Subscriber;
using EasyTab.Subscriber.Consumers;
using EasyTab.Subscriber.Services;

var envFile = Path.Combine(Directory.GetCurrentDirectory(), ".env");
if (!File.Exists(envFile))
{
    envFile = Path.Combine(Directory.GetCurrentDirectory(), "..", ".env");
}
if (File.Exists(envFile))
{
    DotNetEnv.Env.Load(envFile);
}

var host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) =>
    {
        // Email servis
        services.AddScoped<EmailService>();

        // Consumers
        services.AddScoped<UserRegisteredConsumer>();
        services.AddScoped<ReservationCreatedConsumer>();
        services.AddScoped<ReservationConfirmedConsumer>();
        services.AddScoped<ReservationCancelledConsumer>();

        // Worker
        services.AddHostedService<RabbitMQWorker>();
    })
    .Build();

await host.RunAsync();
