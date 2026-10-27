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
