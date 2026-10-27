using System;
using System.Collections.Generic;
using System.Linq;
using System.Globalization;
using EasyTab.Model;
using EasyTab.Model.SearchObject;
using System.Threading.Tasks;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Models;
using EasyTab.Model.Responses;
using EasyTab.Model.Requests;
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
        private readonly IReservationService _reservationService;
        private readonly InitialReservationState _initialState;

        public PaymentService(
            _220030Context context,
            IPayPalService payPalService,
            IOptions<PayPalOptions> payPalOptions,
            ICurrentUserService currentUser,
            ILocaleAccessService localeAccessService,
            INotificationPushService notificationPushService,
            IMapper mapper,
            ILogger<PaymentService> logger,
            IReservationService reservationService,
            InitialReservationState initialState)
        {
            _context = context;
            _payPalService = payPalService;
            _payPalOptions = payPalOptions;
            _currentUser = currentUser;
            _localeAccessService = localeAccessService;
            _notificationPushService = notificationPushService;
            _mapper = mapper;
            _logger = logger;
            _reservationService = reservationService;
            _initialState = initialState;
        }

        public async Task<CreateOrderResponse> CreateOrderAsync(int reservationId)
        {
            var currentUserId = _currentUser.UserId;
            if (currentUserId <= 0)
            {
                throw new ForbiddenException("Korisnički identitet nije pronađen.");
            }

            var reservation = await _context.Reservations
                .Include(r => r.Table)
                .ThenInclude(t => t.Locale)
                .Include(r => r.Payments)
                .FirstOrDefaultAsync(r => r.Id == reservationId);

            if (reservation == null)
            {
                throw new NotFoundException($"Rezervacija sa ID {reservationId} nije pronađena.");
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

            if (reservation.Table.IsRemoved())
                throw new UserException("Stol više nije dostupan za rezervaciju.");

            var startDateTime = reservation.ReservationDate.Date.Add(reservation.StartTime.ToTimeSpan());
            if (startDateTime <= LocalClock.Now)
            {
                throw new UserException("Nije moguće platiti rezervaciju čiji je termin već prošao.");
            }

            if (reservation.Payments.Any(p => p.Status == PaymentStatus.Completed))
            {
                throw new UserException("Rezervacija je već plaćena.");
            }

            // Ako postoji Created payment, provjeri kod PayPala
            var existingCreated = reservation.Payments.FirstOrDefault(p => p.Status == PaymentStatus.Created);
            if (existingCreated?.PayPalOrderId != null)
            {
                PayPalOrderResponse? existingOrder = null;
                try
                {
                    existingOrder = await _payPalService.GetOrderAsync(existingCreated.PayPalOrderId);
                }
                catch (NotFoundException)
                {
                    _logger.LogInformation("PayPal order {OrderId} no longer exists.", existingCreated.PayPalOrderId);
                }

                if (existingOrder != null && string.Equals(existingOrder.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase))
                {
                    var capture = existingOrder.PurchaseUnits?.FirstOrDefault()?.Payments?.Captures?.FirstOrDefault();
                    await CompletePaymentAsync(existingCreated, new PayPalCaptureResult
                    {
                        CaptureId = capture?.Id ?? string.Empty,
                        Status = capture?.Status ?? string.Empty,
                        Amount = decimal.TryParse(capture?.Amount?.Value, NumberStyles.Number,
                            CultureInfo.InvariantCulture, out var amount) ? amount : 0m,
                        Currency = capture?.Amount?.CurrencyCode ?? string.Empty
                    });
                    throw new UserException("Rezervacija je već plaćena.");
                }

                if (existingOrder != null &&
                    !string.Equals(existingOrder.Status, "VOIDED", StringComparison.OrdinalIgnoreCase))
                {
                    if ((existingOrder.Status == "CREATED" || existingOrder.Status == "APPROVED") &&
                        !string.IsNullOrWhiteSpace(existingCreated.ApprovalUrl))
                    {
                        return new CreateOrderResponse
                        {
                            OrderId = existingCreated.PayPalOrderId,
                            ApprovalUrl = existingCreated.ApprovalUrl
                        };
                    }
                    throw new UserException("Postojeća narudžba još nije završena. Pokušajte ponovo kasnije.");
                }
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

            await using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                if (existingCreated != null)
                {
                    var replaced = await _context.Payments
                        .Where(p => p.Id == existingCreated.Id && p.Status == PaymentStatus.Created)
                        .ExecuteUpdateAsync(setters => setters.SetProperty(p => p.Status, PaymentStatus.Failed));
                    if (replaced == 0)
                        throw new UserException("Plaćanje je već pokrenuto za ovu rezervaciju.");
                    await _context.Entry(existingCreated).ReloadAsync();
                }
                _context.Payments.Add(payment);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
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
                throw new ForbiddenException("Korisnički identitet nije pronađen.");
            }

            var payment = await _context.Payments
                .Include(p => p.Reservation)
                .ThenInclude(r => r!.Table)
                .ThenInclude(t => t.Locale)
                .FirstOrDefaultAsync(p => p.PayPalOrderId == orderId);

            if (payment == null)
            {
                throw new NotFoundException($"Plaćanje sa narudžbom {orderId} nije pronađeno.");
            }

            if (payment.CheckoutId.HasValue)
                return await CaptureCheckoutAsync(orderId);
            if (payment.Reservation == null)
                throw new UserException("Rezervacija za ovu uplatu nije pronađena.");

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
                throw new UserException("Rezervacija je već plaćena.");
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

            // PayPal IDs remain unique even when the local database is recreated.
            var requestId = $"capture-{orderId}";
            var captureResult = await _payPalService.CaptureOrderAsync(orderId, requestId);

            return await CompletePaymentAsync(payment, captureResult);
        }

        private async Task<PaymentResponse> CompletePaymentAsync(Payment payment, PayPalCaptureResult captureResult)
        {
            if (payment.Reservation == null)
                throw new UserException("Rezervacija za ovu uplatu nije pronađena.");

            if (string.IsNullOrWhiteSpace(captureResult.CaptureId))
                throw new UserException("Odgovor servisa za plaćanje ne sadrži podatke o naplati.");

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

            var localeName = payment.Reservation.Table?.Locale?.Name ?? "Lokal";
            var notification = new Notification
            {
                UserId = payment.Reservation.UserId,
                Title = "Uplata uspješna",
                Message = $"Vaša uplata za {localeName} u iznosu od {payment.AmountKm:F2} KM ({payment.Amount:F2} {payment.Currency}) je uspješno procesirana.",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            await using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var completedAt = DateTime.UtcNow;
                    var updated = await _context.Payments
                        .Where(p => p.Id == payment.Id && p.Status == PaymentStatus.Created)
                        .ExecuteUpdateAsync(setters => setters
                            .SetProperty(p => p.Status, PaymentStatus.Completed)
                            .SetProperty(p => p.PayPalCaptureId, captureResult.CaptureId)
                            .SetProperty(p => p.CompletedAt, completedAt));
                    await _context.Entry(payment).ReloadAsync();
                    if (updated == 0)
                    {
                        if (payment.Status != PaymentStatus.Completed)
                            throw new UserException("Status plaćanja je promijenjen. Osvježite podatke i pokušajte ponovo.");
                        await transaction.CommitAsync();
                        return _mapper.Map<PaymentResponse>(payment);
                    }
                    _context.Notifications.Add(notification);
                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();
                }
                catch (DbUpdateException ex)
                {
                    _logger.LogError(ex, "Database update error during payment capture commit for payment {PaymentId}", payment.Id);
                    throw new UserException("Greška pri evidentiranju plaćanja u bazi podataka.");
                }
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

        public async Task<Notifications?> RefundCompletedPaymentAsync(int reservationId)
        {
            var completedPayment = await _context.Payments
                .Include(p => p.Reservation)
                .ThenInclude(r => r!.Table)
                .ThenInclude(t => t.Locale)
                .FirstOrDefaultAsync(p => p.ReservationId == reservationId &&
                                          p.Status == PaymentStatus.Completed);

            if (completedPayment == null)
            {
                return null;
            }

            if (completedPayment.Reservation == null)
                throw new UserException("Rezervacija za ovu uplatu nije pronađena.");

            if (string.IsNullOrWhiteSpace(completedPayment.PayPalCaptureId))
                throw new UserException("Povrat uplate nije moguć jer nedostaje podatak o naplati. Rezervacija nije otkazana.");

            var requestId = $"refund-{completedPayment.PayPalCaptureId}";
            var refundResult = await _payPalService.RefundCaptureAsync(
                completedPayment.PayPalCaptureId,
                completedPayment.Amount,
                completedPayment.Currency,
                requestId);

            if (string.Equals(refundResult.Status, "PENDING", StringComparison.OrdinalIgnoreCase))
                _logger.LogWarning("PayPal refund for payment {PaymentId} is PENDING.", completedPayment.Id);
            else if (!string.Equals(refundResult.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning("PayPal refund for payment {PaymentId} failed with status {Status}.", completedPayment.Id, refundResult.Status);
                throw new UserException("Povrat uplate nije uspio. Rezervacija nije otkazana. Pokušajte ponovo kasnije.");
            }

            completedPayment.Status = PaymentStatus.Refunded;
            completedPayment.PayPalRefundId = refundResult.RefundId ?? completedPayment.PayPalRefundId;
            completedPayment.RefundedAmount = completedPayment.Amount;
            completedPayment.RefundedAt = DateTime.UtcNow;

            var localeName = completedPayment.Reservation.Table?.Locale?.Name ?? "Lokal";
            return new Notifications
            {
                UserId = completedPayment.Reservation.UserId,
                Title = "Povrat uplate",
                Message = $"Izvršen je povrat uplate u iznosu od {completedPayment.AmountKm:F2} KM ({completedPayment.Amount:F2} {completedPayment.Currency}) za rezervaciju u {localeName}.",
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };
        }

        public async Task<PagedResult<PaymentResponse>> GetByReservationIdAsync(int reservationId, BaseSearchObject search)
        {
            var reservation = await _context.Reservations
                .Include(r => r.Table)
                .FirstOrDefaultAsync(r => r.Id == reservationId);

            if (reservation == null)
            {
                throw new NotFoundException($"Rezervacija sa ID {reservationId} nije pronađena.");
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

            var pageSize = Math.Clamp(search.PageSize ?? 10, 1, 100);
            var page = Math.Max(search.Page ?? 1, 1);
            var query = _context.Payments.AsNoTracking().Where(p => p.ReservationId == reservationId);
            int? totalCount = search.IncludeTotalCount == true ? await query.CountAsync() : null;
            var offset = (long)(page - 1) * pageSize;
            var payments = offset > int.MaxValue ? new List<Payment>() : await query
                .OrderByDescending(p => p.CreatedAt)
                .ThenByDescending(p => p.Id)
                .Skip((int)offset)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<PaymentResponse>
            {
                Items = _mapper.Map<List<PaymentResponse>>(payments),
                TotalCount = totalCount
            };
        }

        public async Task<CreateOrderResponse> CreateCheckoutAsync(ReservationCheckoutRequest request)
        {
            if (_currentUser.UserId <= 0) throw new ForbiddenException("Potrebna je prijava.");
            if (request.CheckoutId == Guid.Empty || request.TableId <= 0 || request.NumberOfGuests <= 0 ||
                request.StartTime < TimeSpan.Zero || request.EndTime >= TimeSpan.FromDays(1) ||
                request.EndTime <= request.StartTime)
                throw new UserException("Odaberite važeći stol i termin rezervacije.");

            Payment checkout;
            await using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                await LockTableAsync(request.TableId);
                if (!await _context.Tables.OnLayout().AnyAsync(table => table.Id == request.TableId))
                    throw new UserException("Stol više nije dostupan za rezervaciju.");
                var existingCheckout = await _context.Payments.SingleOrDefaultAsync(x => x.CheckoutId == request.CheckoutId);
                if (existingCheckout != null)
                {
                    checkout = existingCheckout;
                    if (checkout.UserId != _currentUser.UserId) throw new ForbiddenException("Nemate pristup ovom plaćanju.");
                    if (checkout.TableId != request.TableId || checkout.ReservationDate != request.ReservationDate.Date ||
                        checkout.StartTime!.Value.ToTimeSpan() != request.StartTime || checkout.EndTime!.Value.ToTimeSpan() != request.EndTime ||
                        checkout.NumberOfGuests != request.NumberOfGuests)
                        throw new UserException("Podaci započetog plaćanja se ne mogu mijenjati.");
                    if (checkout.Status == PaymentStatus.Refunded) throw new UserException("Uplata za ovaj pokušaj je vraćena. Odaberite novi termin.");
                }
                else
                {
                    var table = await _context.Tables.Include(x => x.Locale).SingleAsync(x => x.Id == request.TableId);
                    checkout = new Payment
                    {
                        CheckoutId = request.CheckoutId, UserId = _currentUser.UserId, TableId = request.TableId,
                        NumberOfGuests = request.NumberOfGuests, ReservationDate = request.ReservationDate.Date,
                        StartTime = TimeOnly.FromTimeSpan(request.StartTime), EndTime = TimeOnly.FromTimeSpan(request.EndTime),
                        AmountKm = table.Locale.ReservationPrice,
                        Amount = Math.Round(table.Locale.ReservationPrice / _payPalOptions.Value.BamToEurRate, 2),
                        Currency = _payPalOptions.Value.Currency, CreatedAt = DateTime.UtcNow, Status = PaymentStatus.Created
                    };
                    if (checkout.Amount <= 0 || checkout.AmountKm <= 0)
                        throw new UserException("Cijena rezervacije mora biti veća od nule.");
                    if (!await IsAvailableAsync(checkout)) throw new UserException("Odabrani termin više nije dostupan.");
                    _context.Payments.Add(checkout);
                    await _context.SaveChangesAsync();
                }
                // Save the immutable price before an external call; retries must use the identical payload.
                await transaction.CommitAsync();
            }

            await using var orderTransaction = await _context.Database.BeginTransactionAsync();
            await LockTableAsync(checkout.TableId!.Value);
            await _context.Entry(checkout).ReloadAsync();
            if (checkout.PayPalOrderId == null)
            {
                var order = await _payPalService.CreateOrderAsync(checkout.Amount, checkout.Currency,
                    checkout.CheckoutId!.Value.ToString("N"), "Rezervacija stola", $"co-{checkout.CheckoutId:N}");
                if (string.IsNullOrWhiteSpace(order.approvalUrl))
                    throw new UserException("PayPal nije vratio adresu za odobrenje plaćanja.");
                checkout.PayPalOrderId = order.orderId;
                checkout.ApprovalUrl = order.approvalUrl;
                await _context.SaveChangesAsync();
            }
            await orderTransaction.CommitAsync();
            return new CreateOrderResponse { OrderId = checkout.PayPalOrderId, ApprovalUrl = checkout.ApprovalUrl };
        }

        public async Task<PaymentResponse> CaptureCheckoutAsync(string orderId)
        {
            var checkout = await _context.Payments.AsNoTracking().SingleOrDefaultAsync(x => x.PayPalOrderId == orderId && x.CheckoutId != null)
                ?? throw new NotFoundException("Pokušaj plaćanja nije pronađen.");
            if (_currentUser.UserId <= 0 || checkout.UserId != _currentUser.UserId)
                throw new ForbiddenException("Nemate pristup ovom plaćanju.");
            // Persist intent before contacting PayPal, allowing recovery without the phone.
            await _context.Payments.Where(x => x.Id == checkout.Id && x.CaptureRequestedAt == null)
                .ExecuteUpdateAsync(s => s.SetProperty(x => x.CaptureRequestedAt, DateTime.UtcNow));
            return await CompleteAsync(checkout.Id, allowCapture: true)
                ?? throw new UserException("Plaćanje još nije završeno. Pokušajte ponovo.");
        }

        private async Task<PaymentResponse?> CompleteAsync(int id, bool allowCapture)
        {
            var tableId = await _context.Payments.Where(x => x.Id == id).Select(x => x.TableId).SingleAsync();
            await using var transaction = await _context.Database.BeginTransactionAsync();
            await LockTableAsync(tableId!.Value);
            var checkout = await _context.Payments.SingleAsync(x => x.Id == id);
            await _context.Entry(checkout).ReloadAsync();
            if (checkout.ReservationId.HasValue)
            {
                return _mapper.Map<PaymentResponse>(checkout);
            }
            if (checkout.Status == PaymentStatus.Refunded) throw new UserException("Uplata je vraćena jer termin nije bio dostupan. Rezervacija nije kreirana.");

            var order = await _payPalService.GetOrderAsync(checkout.PayPalOrderId!);
            var captured = order.PurchaseUnits?.SelectMany(x => x.Payments?.Captures ?? []).SingleOrDefault();
            var available = await IsAvailableAsync(checkout);
            PayPalCaptureResult capture;
            if (captured != null)
            {
                capture = new PayPalCaptureResult
                {
                    CaptureId = captured.Id, Status = captured.Status,
                    Amount = decimal.TryParse(captured.Amount?.Value, NumberStyles.Number, CultureInfo.InvariantCulture, out var amount) ? amount : 0,
                    Currency = captured.Amount?.CurrencyCode ?? string.Empty
                };
            }
            else
            {
                if (!allowCapture) return null;
                if (!available) throw new UserException("Termin više nije dostupan. Naplata nije pokrenuta.");
                capture = await _payPalService.CaptureOrderAsync(checkout.PayPalOrderId!, $"capture-{checkout.PayPalOrderId}");
            }
            var alreadyRefunded = string.Equals(capture.Status, "REFUNDED", StringComparison.OrdinalIgnoreCase);
            if ((!string.Equals(capture.Status, "COMPLETED", StringComparison.OrdinalIgnoreCase) && !alreadyRefunded) ||
                string.IsNullOrWhiteSpace(capture.CaptureId))
                throw new UserException("PayPal još nije potvrdio naplatu. Rezervacija nije kreirana.");
            if (capture.Amount != checkout.Amount || !string.Equals(capture.Currency, checkout.Currency, StringComparison.OrdinalIgnoreCase))
                throw new UserException("Iznos ili valuta naplate ne odgovara odabranoj rezervaciji.");

            if (!available || alreadyRefunded)
            {
                var refund = alreadyRefunded
                    ? new PayPalRefundResult { Status = "COMPLETED", AlreadyRefunded = true }
                    : await _payPalService.RefundCaptureAsync(capture.CaptureId, capture.Amount, capture.Currency, $"refund-{capture.CaptureId}");
                if (refund.Status != "COMPLETED" && refund.Status != "PENDING")
                    throw new UserException("Povrat uplate još nije potvrđen. Pokušajte ponovo kasnije.");
                checkout.Status = PaymentStatus.Refunded;
                checkout.PayPalCaptureId = capture.CaptureId;
                checkout.PayPalRefundId = refund.RefundId;
                checkout.RefundedAmount = capture.Amount;
                checkout.RefundedAt = DateTime.UtcNow;
                var notification = new Notification
                {
                    UserId = checkout.UserId!.Value, Title = "Povrat uplate",
                    Message = "Termin više nije dostupan. Pokrenut je povrat uplate; rezervacija nije kreirana.",
                    CreatedAt = DateTime.UtcNow
                };
                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                try { await _notificationPushService.PushAsync(_mapper.Map<Notifications>(notification)); }
                catch (Exception ex) { _logger.LogError(ex, "Checkout refund notification failed for {CheckoutId}.", id); }
                if (allowCapture) throw new UserException(notification.Message);
                return null;
            }
            var created = await _initialState.StagePaidAsync(checkout, capture);
            await _context.SaveChangesAsync();
            await transaction.CommitAsync();
            await _initialState.PublishCreatedAsync(created.Payment, created.Notifications);
            return _mapper.Map<PaymentResponse>(created.Payment);
        }

        private async Task LockTableAsync(int tableId)
        {
            // Serialize checkouts for a table across API instances, including the availability check and capture.
            var table = await _context.Tables.FromSqlInterpolated($"SELECT * FROM [Tables] WITH (UPDLOCK, HOLDLOCK) WHERE [Id] = {tableId}")
                .AsNoTracking().SingleOrDefaultAsync();
            if (table == null) throw new NotFoundException("Stol nije pronađen.");
        }

        private async Task<bool> IsAvailableAsync(Payment checkout)
        {
            var table = await _context.Tables.Include(x => x.Locale).AsNoTracking().SingleAsync(x => x.Id == checkout.TableId);
            if (table.IsRemoved() || table.Locale.IsDeleted || table.NumberOfGuests != checkout.NumberOfGuests ||
                checkout.ReservationDate!.Value.Add(checkout.StartTime!.Value.ToTimeSpan()) <= LocalClock.Now) return false;
            var slots = await _reservationService.GetAvailableSlotsAsync(checkout.TableId!.Value, checkout.ReservationDate!.Value);
            return slots.Any(x =>
                TimeSpan.TryParse(x.Start, CultureInfo.InvariantCulture, out var start) && start == checkout.StartTime!.Value.ToTimeSpan() &&
                TimeSpan.TryParse(x.End, CultureInfo.InvariantCulture, out var end) && end == checkout.EndTime!.Value.ToTimeSpan());
        }

        public async Task ReconcileCheckoutsAsync(CancellationToken cancellationToken)
        {
            var ids = await _context.Payments.AsNoTracking()
                .Where(x => x.CheckoutId != null && x.CaptureRequestedAt != null && x.ReservationId == null && x.Status == PaymentStatus.Created && x.PayPalOrderId != null)
                .OrderBy(x => x.LastCheckedAt).ThenBy(x => x.CreatedAt).Select(x => x.Id)
                .Take(100).ToListAsync(cancellationToken);
            foreach (var id in ids)
            {
                cancellationToken.ThrowIfCancellationRequested();
                try { await CompleteAsync(id, allowCapture: false); }
                catch (Exception ex) { _logger.LogError(ex, "Checkout reconciliation failed for {CheckoutId}.", id); }
                finally
                {
                    _context.ChangeTracker.Clear();
                    await _context.Payments.Where(x => x.Id == id)
                        .ExecuteUpdateAsync(s => s.SetProperty(x => x.LastCheckedAt, DateTime.UtcNow), cancellationToken);
                }
            }
        }
    }
}
