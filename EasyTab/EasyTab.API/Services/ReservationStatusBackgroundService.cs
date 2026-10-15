using EasyTab.Services;
using EasyTab.Services.Interfaces;

namespace EasyTab.API.Services;

public sealed class ReservationStatusBackgroundService : BackgroundService
{
    private static readonly TimeSpan CycleInterval = TimeSpan.FromMinutes(1);
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ReservationStatusBackgroundService> _logger;

    public ReservationStatusBackgroundService(
        IServiceScopeFactory scopeFactory,
        ILogger<ReservationStatusBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await using var scope = _scopeFactory.CreateAsyncScope();
                var reservationService = scope.ServiceProvider
                    .GetRequiredService<IReservationService>();
                await reservationService.ProcessAutomaticTransitionsAsync(LocalClock.Now);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Automatic reservation status cycle failed.");
            }

            try
            {
                await Task.Delay(CycleInterval, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                break;
            }
        }
    }
}
