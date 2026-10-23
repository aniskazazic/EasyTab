using EasyTab.Model.Messages;
using EasyTab.Model.Models;
using EasyTab.Model.Exceptions;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.PayPal;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace EasyTab.Services.ReservationStateMachine;

public class InitialReservationState : BaseReservationState
{
    public InitialReservationState(_220030Context context, IMapper mapper, IServiceProvider serviceProvider)
        : base(context, mapper, serviceProvider) { }

    public async Task<(Payment Payment, List<Notification> Notifications)> StagePaidAsync(
        Payment checkout, PayPalCaptureResult capture)
    {
        if (_context.Database.CurrentTransaction == null)
            throw new InvalidOperationException("Paid reservation creation requires a transaction.");
        if (capture.Status != "COMPLETED" || string.IsNullOrWhiteSpace(capture.CaptureId) ||
            capture.Amount != checkout.Amount || !string.Equals(capture.Currency, checkout.Currency, StringComparison.OrdinalIgnoreCase))
            throw new UserException("Naplata nije potvrđena za ovu rezervaciju.");

        var table = await _context.Tables.Include(x => x.Locale).SingleAsync(x => x.Id == checkout.TableId);
        var user = await _context.Users.SingleAsync(x => x.Id == checkout.UserId);
        var reservation = new Reservation
        {
            User = user, Table = table, ReservationDate = checkout.ReservationDate!.Value,
            StartTime = checkout.StartTime!.Value, EndTime = checkout.EndTime!.Value,
            CreatedAt = DateTime.UtcNow, ReservationState = PendingReservationState.StateName
        };
        checkout.Reservation = reservation;
        checkout.PayPalCaptureId = capture.CaptureId;
        checkout.Status = PaymentStatus.Completed;
        checkout.CompletedAt = DateTime.UtcNow;
        var payment = checkout;
        var notifications = new List<Notification>
        {
            new()
            {
                UserId = user.Id, Title = "Rezervacija plaćena",
                Message = $"Vaša rezervacija za {table.Locale.Name} ({reservation.ReservationDate:dd.MM.yyyy} u {reservation.StartTime:HH:mm}) je plaćena ({payment.AmountKm:F2} KM) i čeka potvrdu lokala.",
                CreatedAt = DateTime.UtcNow
            }
        };
        var access = _serviceProvider.GetRequiredService<ILocaleAccessService>();
        foreach (var managerId in (await access.GetLocaleManagerUserIdsAsync(table.LocaleId)).Where(id => id != user.Id))
        {
            notifications.Add(new Notification
            {
                UserId = managerId, Title = "Nova rezervacija",
                Message = $"Nova plaćena rezervacija za {table.Locale.Name} ({reservation.ReservationDate:dd.MM.yyyy} u {reservation.StartTime:HH:mm}) čeka potvrdu.",
                CreatedAt = DateTime.UtcNow
            });
        }
        _context.Notifications.AddRange(notifications);
        return (payment, notifications);
    }

    public async Task PublishCreatedAsync(Payment payment, List<Notification> notifications)
    {
        await PushNotificationsAsync(notifications);
        var reservation = payment.Reservation!;
        try
        {
            await _serviceProvider.GetRequiredService<IRabbitMQPublisher>().PublishReservationCreatedAsync(
                new ReservationCreatedMessage
                {
                    ReservationId = reservation.Id, UserId = reservation.UserId,
                    UserEmail = reservation.User.Email,
                    UserFullName = $"{reservation.User.FirstName} {reservation.User.LastName}",
                    LocaleName = reservation.Table.Locale.Name,
                    ReservationDate = reservation.ReservationDate,
                    StartTime = reservation.StartTime.ToString("HH:mm"),
                    EndTime = reservation.EndTime.ToString("HH:mm"),
                    NumberOfGuests = reservation.Table.NumberOfGuests
                });
        }
        catch (Exception ex)
        {
            _serviceProvider.GetRequiredService<ILogger<InitialReservationState>>()
                .LogError(ex, "Reservation email publication failed after commit for {ReservationId}.", reservation.Id);
        }
    }
}
