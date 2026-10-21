using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Models;
using EasyTab.Model.Responses;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.PayPal;
using EasyTab.Services.ReservationStateMachine;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace EasyTab.Services.Services
{
    public class PaymentService : IPaymentService
    {
        private readonly _220030Context _context;
        private readonly IPayPalService _payPalService;
        private readonly IOptions<PayPalOptions> _payPalOptions;
        private readonly ICurrentUserService _currentUser;
        private readonly ILocaleAccessService _localeAccessService;
        private readonly INotificationPushService _notificationPushService;
        private readonly IMapper _mapper;
        private readonly ILogger<PaymentService> _logger;

        public PaymentService(
            _220030Context context,
            IPayPalService payPalService,
            IOptions<PayPalOptions> payPalOptions,
            ICurrentUserService currentUser,
            ILocaleAccessService localeAccessService,
            INotificationPushService notificationPushService,
            IMapper mapper,
            ILogger<PaymentService> logger)
        {
            _context = context;
            _payPalService = payPalService;
            _payPalOptions = payPalOptions;
            _currentUser = currentUser;
            _localeAccessService = localeAccessService;
            _notificationPushService = notificationPushService;
            _mapper = mapper;
            _logger = logger;
        }

        public async Task<CreateOrderResponse> CreateOrderAsync(int reservationId)
        {
            var currentUserId = _currentUser.UserId;
            if (currentUserId <= 0)
            {
                throw new UnauthorizedAccessException("Korisnički identitet nije pronađen.");
            }

            var reservation = await _context.Reservations
                .Include(r => r.Table)
                .ThenInclude(t => t.Locale)
                .Include(r => r.Payments)
                .FirstOrDefaultAsync(r => r.Id == reservationId);

            if (reservation == null)
            {
                throw new KeyNotFoundException($"Rezervacija sa ID {reservationId} nije pronađena.");
            }

            // Samo za prijavljenog vlasnika rezervacije, bez admin izuzetka
            if (reservation.UserId != currentUserId)
            {
                throw new ForbiddenException("Nemate pristup plaćanju ove rezervacije.");
            }

            var isAllowedState = reservation.ReservationState == PendingReservationState.StateName ||
                                 reservation.ReservationState == ConfirmedReservationState.StateName;
            if (!isAllowedState)
            {
                throw new UserException("Plaćanje je moguće samo za rezervacije na čekanju ili potvrđene rezervacije.");
            }

            var startDateTime = reservation.ReservationDate.Date.Add(reservation.StartTime.ToTimeSpan());
            if (startDateTime <= LocalClock.Now)
            {
                throw new UserException("Nije moguće platiti rezervaciju čiji je termin već prošao.");
            }

            if (reservation.Payments.Any(p => p.Status == PaymentStatus.Completed))
            {
                throw new UserException("Rezervacija je vec placena.");
            }

            // Ako postoji Created payment, provjeri kod PayPala
            var existingCreated = reservation.Payments.FirstOrDefault(p => p.Status == PaymentStatus.Created);
            if (existingCreated != null)
            {
                bool isOrderReusable = false;
                try
                {
                    var existingOrder = await _payPalService.GetOrderAsync(existingCreated.PayPalOrderId);
                    if (existingOrder.Status == "CREATED" || existingOrder.Status == "APPROVED")
                    {
                        isOrderReusable = true;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogInformation(ex, "Existing PayPal order {OrderId} is not reusable.", existingCreated.PayPalOrderId);
                    isOrderReusable = false;
                }

                if (isOrderReusable && !string.IsNullOrEmpty(existingCreated.ApprovalUrl))
                {
                    return new CreateOrderResponse
                    {
                        OrderId = existingCreated.PayPalOrderId,
                        ApprovalUrl = existingCreated.ApprovalUrl
                    };
                }

                // Zamjena isteklog ordera: prvo SaveChangesAsync sa starim redom označenim Failed
                existingCreated.Status = PaymentStatus.Failed;
                await _context.SaveChangesAsync();
            }

            var amountKm = reservation.Table?.Locale?.ReservationPrice ?? 0m;
            if (amountKm <= 0)
            {
                throw new UserException("Iznos za plaćanje mora biti veći od 0.");
            }

            var amountEur = Math.Round(amountKm / _payPalOptions.Value.BamToEurRate, 2);
            if (amountEur <= 0)
            {
                throw new UserException("Iznos za plaćanje mora biti veći od 0.");
            }

            var currency = _payPalOptions.Value.Currency;
            var localeName = reservation.Table?.Locale?.Name ?? "Lokal";
            var (orderId, approvalUrl) = await _payPalService.CreateOrderAsync(
                amountEur,
                currency,
                $"res-{reservation.Id}",
                $"Rezervacija #{reservation.Id} - {localeName}");

            var payment = new Payment
            {
                ReservationId = reservation.Id,
                AmountKm = amountKm,
                Amount = amountEur,
                Currency = currency,
                ApprovalUrl = approvalUrl,
                PayPalOrderId = orderId,
                Status = PaymentStatus.Created,
                CreatedAt = DateTime.UtcNow
            };

            _context.Payments.Add(payment);

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException ex)
            {
                _logger.LogWarning(ex, "DbUpdateException on creating payment for reservation {ReservationId}", reservation.Id);
                throw new UserException("Plaćanje je već pokrenuto za ovu rezervaciju.");
            }

            return new CreateOrderResponse
            {
                OrderId = orderId,
                ApprovalUrl = approvalUrl
            };
        }

        public async Task<PaymentResponse> CaptureOrderAsync(string orderId)
        {
            var currentUserId = _currentUser.UserId;
            if (currentUserId <= 0)
            {
                throw new UnauthorizedAccessException("Korisnički identitet nije pronađen.");
            }

            var payment = await _context.Payments
                .Include(p => p.Reservation)
                .ThenInclude(r => r.Table)
                .ThenInclude(t => t.Locale)
                .FirstOrDefaultAsync(p => p.PayPalOrderId == orderId);

            if (payment == null)
            {
                throw new KeyNotFoundException($"Plaćanje sa narudžbom {orderId} nije pronađeno.");
            }

            // Samo za prijavljenog vlasnika rezervacije, bez admin izuzetka
            if (payment.Reservation.UserId != currentUserId)
            {
                _logger.LogWarning(
                    "Capture rejected by local check: reservation {ReservationId} belongs to UserId={OwnerId}, but current authenticated user is UserId={CurrentUserId}.",
                    payment.Reservation.Id, payment.Reservation.UserId, currentUserId);
                throw new ForbiddenException("Nemate pristup ovoj rezervaciji.");
            }

            // Idempotentno
            if (payment.Status == PaymentStatus.Completed)
            {
                _logger.LogInformation("Capture idempotent return: payment {PaymentId} is already Completed.", payment.Id);
                return _mapper.Map<PaymentResponse>(payment);
            }

            if (payment.Status != PaymentStatus.Created)
            {
                throw new UserException("Ova narudzba vise nije vazeca. Pokrenite placanje ponovo.");
            }

            var hasCompletedPayment = await _context.Payments
                .AnyAsync(p => p.ReservationId == payment.ReservationId &&
                               p.Id != payment.Id &&
                               p.Status == PaymentStatus.Completed);
            if (hasCompletedPayment)
            {
                throw new UserException("Rezervacija je vec placena.");
            }

            var isAllowedState = payment.Reservation.ReservationState == PendingReservationState.StateName ||
                                 payment.Reservation.ReservationState == ConfirmedReservationState.StateName;
            if (!isAllowedState)
            {
                _logger.LogWarning(
                    "Capture rejected by local check: reservation {ReservationId} is in state '{State}', expected Pending or Confirmed.",
                    payment.Reservation.Id, payment.Reservation.ReservationState);
                throw new UserException("Plaćanje je moguće samo za rezervacije na čekanju ili potvrđene rezervacije.");
            }

            var startDateTime = payment.Reservation.ReservationDate.Date.Add(payment.Reservation.StartTime.ToTimeSpan());
            if (startDateTime <= LocalClock.Now)
            {
                _logger.LogWarning(
                    "Capture rejected by local check: reservation {ReservationId} start time {StartDateTime} is in the past (LocalClock.Now: {Now}).",
                    payment.Reservation.Id, startDateTime, LocalClock.Now);
                throw new UserException("Nije moguće izvršiti naplatu za rezervaciju čiji je termin prošao.");
            }

            // Deterministički PayPal-Request-Id (capture-{paymentId})
            var requestId = $"capture-{payment.Id}";
            var captureResult = await _payPalService.CaptureOrderAsync(orderId, requestId);

            if (!string.Equals(captureResult.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogError("CaptureOrder failed: PayPal capture status is '{Status}', expected 'COMPLETED'.", captureResult.Status);
                throw new UserException("PayPal naplata nije završena sa statusom COMPLETED.");
            }

            // Usporedba iznosa kao decimal i valute case-insensitive
            var isAmountMatch = Math.Abs(captureResult.Amount - payment.Amount) < 0.01m;
            var isCurrencyMatch = string.Equals(captureResult.Currency, payment.Currency, StringComparison.OrdinalIgnoreCase);

            if (!isAmountMatch || !isCurrencyMatch)
            {
                _logger.LogError(
                    "Payment capture mismatch for Payment {PaymentId}. Expected Amount: {ExpAmount}, Captured Amount: {ActAmount} (Match: {IsAmountMatch}). Expected Currency: '{ExpCur}', Captured Currency: '{ActCur}' (Match: {IsCurrencyMatch}).",
                    payment.Id, payment.Amount, captureResult.Amount, isAmountMatch, payment.Currency, captureResult.Currency, isCurrencyMatch);
                throw new UserException("Iznos ili valuta naplate ne odgovara podacima rezervacije.");
            }

            payment.Status = PaymentStatus.Completed;
            payment.PayPalCaptureId = captureResult.CaptureId;
            payment.CompletedAt = DateTime.UtcNow;

            var localeName = payment.Reservation.Table?.Locale?.Name ?? "Lokal";
            var notification = new Notification
            {
                UserId = payment.Reservation.UserId,
                Title = "Uplata uspješna",
                Message = $"Vaša uplata za {localeName} u iznosu od {payment.AmountKm:F2} KM ({payment.Amount:F2} {payment.Currency}) je uspješno procesirana.",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            try
            {
                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateException ex)
            {
                _logger.LogError(ex, "Database update error during payment capture commit for payment {PaymentId}", payment.Id);
                throw new UserException("Greška pri evidentiranju plaćanja u bazi podataka.");
            }

            // SignalR push se šalje tek nakon što je transakcija commitovana
            try
            {
                await _notificationPushService.PushAsync(_mapper.Map<Notifications>(notification));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Push notification delivery failed for user {UserId}", payment.Reservation.UserId);
            }

            return _mapper.Map<PaymentResponse>(payment);
        }

        public async Task<Notification?> RefundCompletedPaymentAsync(int reservationId)
        {
            var completedPayment = await _context.Payments
                .Include(p => p.Reservation)
                .ThenInclude(r => r.Table)
                .ThenInclude(t => t.Locale)
                .FirstOrDefaultAsync(p => p.ReservationId == reservationId &&
                                          p.Status == PaymentStatus.Completed);

            if (completedPayment == null || string.IsNullOrEmpty(completedPayment.PayPalCaptureId))
            {
                return null;
            }

            var requestId = $"refund-{completedPayment.Id}";
            var refundResult = await _payPalService.RefundCaptureAsync(
                completedPayment.PayPalCaptureId,
                completedPayment.Amount,
                completedPayment.Currency,
                requestId);

            completedPayment.Status = PaymentStatus.Refunded;
            completedPayment.PayPalRefundId = refundResult.RefundId ?? completedPayment.PayPalRefundId;
            completedPayment.RefundedAmount = completedPayment.Amount;
            completedPayment.RefundedAt = DateTime.UtcNow;

            var localeName = completedPayment.Reservation.Table?.Locale?.Name ?? "Lokal";
            return new Notification
            {
                UserId = completedPayment.Reservation.UserId,
                Title = "Povrat uplate",
                Message = $"Izvršen je povrat uplate u iznosu od {completedPayment.AmountKm:F2} KM ({completedPayment.Amount:F2} {completedPayment.Currency}) za rezervaciju u {localeName}.",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };
        }

        public async Task<List<PaymentResponse>> GetByReservationIdAsync(int reservationId)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == reservationId);

            if (reservation == null)
            {
                throw new KeyNotFoundException($"Rezervacija sa ID {reservationId} nije pronađena.");
            }

            var currentUserId = _currentUser.UserId;
            var isReservationOwner = reservation.UserId == currentUserId;

            if (!isReservationOwner)
            {
                if (reservation.Table != null)
                {
                    await _localeAccessService.EnsureCanManageLocaleAsync(reservation.Table.LocaleId);
                }
                else if (!_currentUser.IsAdmin)
                {
                    throw new ForbiddenException("Nemate pristup informacijama o plaćanju ove rezervacije.");
                }
            }

            var payments = await _context.Payments
                .AsNoTracking()
                .Where(p => p.ReservationId == reservationId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync();

            return _mapper.Map<List<PaymentResponse>>(payments);
        }
    }
}
