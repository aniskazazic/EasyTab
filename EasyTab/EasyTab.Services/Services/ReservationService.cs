using EasyTab.Model.Models;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Requests;
using EasyTab.Model;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.ReservationStateMachine;
using EasyTab.Services;
using FluentValidation;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Services
{
    public class ReservationService : BaseCRUDService<Reservations, ReservationSearchObject, Reservation, ReservationInsertRequest, ReservationUpdateRequest>, IReservationService
    {
        private readonly ILogger<ReservationService> _logger;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILocaleAccessService _localeAccessService;
        private readonly ICurrentUserService _currentUser;

        public ReservationService(_220030Context context, IMapper mapper, ILogger<ReservationService> logger, IServiceProvider serviceProvider, IValidator<ReservationInsertRequest> insertValidator, IValidator<ReservationUpdateRequest> updateValidator, ILocaleAccessService localeAccessService, ICurrentUserService currentUser) : base(context, mapper, insertValidator, updateValidator)
        {
            _logger = logger;
            _serviceProvider = serviceProvider;
            _localeAccessService = localeAccessService;
            _currentUser = currentUser;
        }

        protected override IQueryable<Reservation> ApplyFilter(IQueryable<Reservation> query, ReservationSearchObject search)
        {
            query = query.Include(r => r.Table)
                         .ThenInclude(t => t.Locale)
                         .Include(r => r.User);

            if (_currentUser.IsAdmin)
            {
                if (search?.UserId.HasValue == true)
                    query = query.Where(x => x.UserId == search.UserId.Value);
            }
            else if (_currentUser.Role == RoleNames.Vlasnik)
            {
                query = query.Where(x => x.Table.Locale.OwnerId == _currentUser.UserId);
            }
            else if (_currentUser.Role == RoleNames.Radnik)
            {
                query = query.Where(x => x.Table.Locale.Workers.Any(worker =>
                    worker.UserId == _currentUser.UserId && !worker.IsDeleted));
            }
            else
            {
                query = query.Where(x => x.UserId == _currentUser.UserId);
            }

            if (search?.TableId.HasValue == true)
                query = query.Where(x => x.TableId == search.TableId);

            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.Table.LocaleId == search.LocaleId);

            if (search?.ReservationDate.HasValue == true)
            {
                var date = search.ReservationDate.Value.Date;
                var nextDate = date.AddDays(1);
                query = query.Where(x => x.ReservationDate >= date &&
                                         x.ReservationDate < nextDate);
            }

            if (search?.ReservationState != null)
                query = query.Where(x => x.ReservationState == search.ReservationState);

            if (!string.IsNullOrWhiteSpace(search?.PaymentStatus))
            {
                query = search.PaymentStatus switch
                {
                    "Paid" => query.Where(r => Context.Payments.Any(p => p.ReservationId == r.Id && p.Status == PaymentStatus.Completed)
                        && !Context.Payments.Any(p => p.ReservationId == r.Id && p.Status == PaymentStatus.Refunded)),
                    "Refunded" => query.Where(r => Context.Payments.Any(p => p.ReservationId == r.Id && p.Status == PaymentStatus.Refunded)),
                    "Unpaid" => query.Where(r => !Context.Payments.Any(p => p.ReservationId == r.Id &&
                        (p.Status == PaymentStatus.Completed || p.Status == PaymentStatus.Refunded))),
                    _ => throw new UserException("Nepoznat status plaćanja.")
                };
            }

            // Aktivne rezervacije: samo one koje nisu otkazane/završene i čiji termin još nije prošao
            if (search?.IsUpcoming == true)
            {
                var now = LocalClock.Now;
                query = query.Where(r =>
                    r.ReservationState != CancelledReservationState.StateName &&
                    r.ReservationState != CompletedReservationState.StateName &&
                    (r.ReservationDate.Date > now.Date ||
                    (r.ReservationDate.Date == now.Date && r.StartTime >= TimeOnly.FromTimeSpan(now.TimeOfDay))));
            }
            // Prošle / historija rezervacije: otkazane, završene ili one čiji je termin prošao
            else if (search?.IsUpcoming == false)
            {
                var now = LocalClock.Now;
                query = query.Where(r =>
                    r.ReservationState == CancelledReservationState.StateName ||
                    r.ReservationState == CompletedReservationState.StateName ||
                    r.ReservationDate.Date < now.Date ||
                    (r.ReservationDate.Date == now.Date && r.StartTime < TimeOnly.FromTimeSpan(now.TimeOfDay)));
            }

            if (string.IsNullOrWhiteSpace(search?.SortBy))
            {
                if (search?.IsUpcoming == true)
                {
                    query = query.OrderBy(x => x.ReservationDate)
                                 .ThenBy(x => x.StartTime)
                                 .ThenBy(x => x.Id);
                }
                else if (search?.IsUpcoming == false)
                {
                    query = query.OrderByDescending(x => x.ReservationState == CancelledReservationState.StateName)
                                 .ThenByDescending(x => x.CancelledAt)
                                 .ThenByDescending(x => x.ReservationDate)
                                 .ThenByDescending(x => x.StartTime)
                                 .ThenByDescending(x => x.Id);
                }
                else
                {
                    query = query.OrderByDescending(x => x.ReservationDate)
                                 .ThenBy(x => x.StartTime)
                                 .ThenBy(x => x.Id);
                }
            }

            return query;
        }

        protected override Reservations MapToResponse(Reservation entity)
        {
            var dto = base.MapToResponse(entity);

            if (entity.User != null)
            {
                dto.FirstName = entity.User.FirstName;
                dto.LastName = entity.User.LastName;
                dto.Email = entity.User.Email;
                dto.PhoneNumber = entity.User.PhoneNumber;
            }

            if (entity.Table != null)
            {
                dto.TableName = entity.Table.Name;
                dto.NumberOfGuests = entity.Table.NumberOfGuests;

                if (entity.Table.Locale != null)
                {
                    dto.LocaleId = entity.Table.Locale.Id;
                    dto.LocaleName = entity.Table.Locale.Name;
                    dto.LocaleAddress = entity.Table.Locale.Address;
                    dto.LocaleLogo = entity.Table.Locale.Logo;
                }
            }

            return dto;
        }

        public override async Task<PagedResult<Reservations>> GetAsync(ReservationSearchObject search)
        {
            var pagedResult = await base.GetAsync(search);

            if (pagedResult.Items != null && pagedResult.Items.Count > 0)
            {
                var reservationIds = pagedResult.Items.Select(r => r.Id).ToList();
                var payments = await Context.Payments
                    .AsNoTracking()
                    .Where(p => p.ReservationId.HasValue && reservationIds.Contains(p.ReservationId.Value) &&
                        (p.Status == PaymentStatus.Completed || p.Status == PaymentStatus.Refunded))
                    .OrderByDescending(p => p.Status == PaymentStatus.Refunded)
                    .ThenByDescending(p => p.CompletedAt ?? p.CreatedAt)
                    .ThenByDescending(p => p.Id)
                    .ToListAsync();
                var byReservation = payments.GroupBy(p => p.ReservationId!.Value)
                    .ToDictionary(g => g.Key, g => g.First());

                foreach (var item in pagedResult.Items)
                {
                    byReservation.TryGetValue(item.Id, out var payment);
                    SetPaymentDetails(item, payment);
                }
            }

            return pagedResult;
        }

        public override async Task<Reservations?> GetByIdAsync(int id)
        {
            var entity = await Context.Reservations
                .Include(r => r.Table)
                    .ThenInclude(t => t.Locale)
                        .ThenInclude(l => l.Workers)
                .Include(r => r.User)
                .FirstOrDefaultAsync(r => r.Id == id);

            if (entity == null)
                return null;

            if (!CanAccessReservation(entity))
                return null;

            var dto = MapToResponse(entity);
            var payment = await Context.Payments
                .AsNoTracking()
                .Where(p => p.ReservationId == id && (p.Status == PaymentStatus.Completed || p.Status == PaymentStatus.Refunded))
                .OrderByDescending(p => p.Status == PaymentStatus.Refunded)
                .ThenByDescending(p => p.CompletedAt ?? p.CreatedAt)
                .ThenByDescending(p => p.Id)
                .FirstOrDefaultAsync();

            SetPaymentDetails(dto, payment);

            return dto;
        }

        private static void SetPaymentDetails(Reservations dto, Payment? payment)
        {
            dto.IsPaid = payment?.Status == PaymentStatus.Completed;
            dto.PaidAmountKm = dto.IsPaid ? payment!.AmountKm : null;
            dto.RefundedAmountKm = payment?.Status == PaymentStatus.Refunded ? payment.AmountKm : null;
            dto.PaidAt = payment?.CompletedAt;
            dto.RefundedAt = payment?.RefundedAt;
        }

        public async Task<PaymentSummary> GetPaymentSummaryAsync(PaymentSummarySearchObject search)
        {
            if (!_currentUser.IsAdmin && _currentUser.Role != RoleNames.Vlasnik)
                throw new ForbiddenException("Nemate dozvolu za pregled izvještaja o plaćanju.");

            var to = search.To?.Date ?? LocalClock.Now.Date;
            var from = search.From?.Date ?? to.AddDays(-29);
            if (to < from)
                throw new UserException("Datum do ne smije biti prije datuma od.");
            if (to == DateTime.MaxValue.Date)
                throw new UserException("Datum do je izvan dozvoljenog raspona.");

            if (!_currentUser.IsAdmin && search.LocaleId.HasValue &&
                !await Context.Locales.AnyAsync(l => l.Id == search.LocaleId.Value && l.OwnerId == _currentUser.UserId))
                throw new ForbiddenException("Nemate dozvolu za pregled plaćanja ovog lokala.");

            var startUtc = TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(from, DateTimeKind.Unspecified), TimeZoneInfo.Local);
            var endUtc = TimeZoneInfo.ConvertTimeToUtc(DateTime.SpecifyKind(to.AddDays(1), DateTimeKind.Unspecified), TimeZoneInfo.Local);
            var payments = Context.Payments.AsNoTracking();
            // Select one effective locale per payment; no join/concat can duplicate a payment.
            var locales = Context.Locales.AsNoTracking();
            if (!_currentUser.IsAdmin)
                locales = locales.Where(l => l.OwnerId == _currentUser.UserId);
            if (search.LocaleId.HasValue)
                locales = locales.Where(l => l.Id == search.LocaleId.Value);
            payments = payments.Where(p => locales.Any(l => l.Id ==
                (p.Reservation != null ? (int?)p.Reservation.Table.LocaleId :
                    Context.Tables.Where(t => t.Id == p.TableId).Select(t => (int?)t.LocaleId).FirstOrDefault())));

            return await payments.GroupBy(p => 1).Select(g => new PaymentSummary
            {
                TotalCollectedKm = g.Sum(p =>
                    (p.Status == PaymentStatus.Completed || p.Status == PaymentStatus.Refunded) &&
                    p.CompletedAt >= startUtc && p.CompletedAt < endUtc ? p.AmountKm : 0m),
                TotalRefundedKm = g.Sum(p => p.Status == PaymentStatus.Refunded &&
                    p.RefundedAt >= startUtc && p.RefundedAt < endUtc ? p.AmountKm : 0m)
            }).SingleOrDefaultAsync() ?? new PaymentSummary();
        }

        private bool CanAccessReservation(Reservation reservation)
        {
            if (_currentUser.IsAdmin)
                return true;

            if (_currentUser.Role == RoleNames.Vlasnik)
                return reservation.Table.Locale.OwnerId == _currentUser.UserId;

            if (_currentUser.Role == RoleNames.Radnik)
                return reservation.Table.Locale.Workers.Any(worker =>
                    worker.UserId == _currentUser.UserId && !worker.IsDeleted);

            return reservation.UserId == _currentUser.UserId;
        }

        public async Task<List<TimeSlots>> GetAvailableSlotsAsync(int tableId, DateTime date)
        {
            var locale = Context.Tables
                .Include(x => x.Locale)
                .Where(x => x.Id == tableId)
                .Select(x => x.Locale)
                .FirstOrDefaultAsync();
            var localeEntity = await locale;

            if (localeEntity == null)
            {
                _logger.LogWarning("Cannot fetch available slots because locale was not found. TableId: {TableId}", tableId);
                throw new UserException("Lokal nije pronađen!");
            }

            var open = localeEntity.StartOfWorkingHours.ToTimeSpan();
            var close = localeEntity.EndOfWorkingHours.ToTimeSpan();

            // Fallback ako radno vrijeme nije podešeno u bazi ili je 00:00 - 00:00
            if (open == TimeSpan.Zero && close == TimeSpan.Zero)
            {
                open = new TimeSpan(8, 0, 0);   // 08:00
                close = new TimeSpan(23, 0, 0); // 23:00
            }
            else if (close <= open)
            {
                if (close == TimeSpan.Zero)
                {
                    close = TimeSpan.FromHours(24); // 24:00 (kraj dana)
                }
                else
                {
                    close = new TimeSpan(23, 0, 0);
                }
            }

            var slotHours = (localeEntity.LengthOfReservation > 0) ? localeEntity.LengthOfReservation : 2.0;
            var slotLength = TimeSpan.FromHours(slotHours);

            // Generiši sve slotove
            var allSlots = new List<(TimeSpan Start, TimeSpan End)>();
            for (var t = open; t + slotLength <= close; t += slotLength)
            {
                allSlots.Add((t, t + slotLength));
            }

            // Dohvati zauzete termine
            var reserved = Context.Reservations
                .Where(r => r.TableId == tableId &&
                            r.ReservationDate.Date == date.Date &&
                            r.ReservationState != CancelledReservationState.StateName)
                .Select(r => new { r.StartTime, r.EndTime })
                .ToListAsync();
            var reservedSlots = await reserved;

            var now = LocalClock.Now;

            string FormatSlotTime(TimeSpan ts)
            {
                int h = (int)ts.TotalHours;
                if (h >= 24) h %= 24;
                int m = ts.Minutes;
                return $"{h:D2}:{m:D2}";
            }

            // Filtriraj slobodne slotove
            var slots = allSlots
                .Where(slot =>
                    !reservedSlots.Any(res =>
                        slot.Start < res.EndTime.ToTimeSpan() && res.StartTime.ToTimeSpan() < slot.End) &&
                    date.Date.Add(slot.Start) > now)
                .Select(s => new TimeSlots
                {
                    Start = FormatSlotTime(s.Start),
                    End = FormatSlotTime(s.End)
                })
                .ToList();

            _logger.LogDebug("Available slots fetched. TableId: {TableId}, Count: {Count}", tableId, slots.Count);
            return slots;
        }

        public async Task CancelReservationAsync(int id, string reason)
        {
            _logger.LogWarning("Cancelling reservation. ReservationId: {ReservationId}", id);
            var reservation = await Context.Reservations
                .Include(x => x.Table)
                    .ThenInclude(x => x.Locale)
                        .ThenInclude(x => x.Workers)
                .FirstOrDefaultAsync(x => x.Id == id);
            if (reservation == null)
            {
                _logger.LogWarning("Cannot cancel reservation because it was not found. ReservationId: {ReservationId}", id);
                throw new UserException("Rezervacija nije pronađena!");
            }

            if (string.IsNullOrWhiteSpace(reason))
            {
                throw new UserException("Razlog otkazivanja je obavezan.");
            }

            if (_currentUser.Role == RoleNames.Vlasnik || _currentUser.Role == RoleNames.Radnik || _currentUser.IsAdmin)
            {
                await _localeAccessService.EnsureCanManageLocaleAsync(reservation.Table.LocaleId);
            }
            else if (reservation.UserId != _currentUser.UserId)
            {
                throw new UserException("Možete otkazati samo vlastitu rezervaciju.");
            }

            var state = GetStateMachine(reservation.ReservationState);
            await state.CancelAsync(id, reason, _currentUser.UserId);
            _logger.LogWarning("Reservation cancelled successfully. ReservationId: {ReservationId}", id);
        }

        public override Task<Reservations> CreateAsync(ReservationInsertRequest request)
        {
            throw new UserException("Rezervacija se kreira tek nakon uspješnog plaćanja. Pokrenite plaćanje za odabrani stol i termin.");
        }

        public async Task<Reservations> ConfirmAsync(int id)
        {
            var reservation = await Context.Reservations
                .Include(x => x.Table)
                .FirstOrDefaultAsync(x => x.Id == id);
            if (reservation == null)
            {
                throw new UserException("Rezervacija nije pronađena!");
            }

            await _localeAccessService.EnsureCanManageLocaleAsync(reservation.Table.LocaleId);

            var state = GetStateMachine(reservation.ReservationState);
            return await state.ConfirmAsync(id, _currentUser.UserId);
        }

        public async Task<Reservations> CompleteAsync(int id)
        {
            var reservation = await Context.Reservations
                .Include(x => x.Table)
                .FirstOrDefaultAsync(x => x.Id == id);
            if (reservation == null)
            {
                throw new UserException("Rezervacija nije pronađena!");
            }

            await _localeAccessService.EnsureCanManageLocaleAsync(reservation.Table.LocaleId);

            var state = GetStateMachine(reservation.ReservationState);
            return await state.CompleteAsync(id);
        }

        public async Task<List<string>> GetAllowedActionsAsync(int id)
        {
            var reservation = await Context.Reservations
                .Include(x => x.Table)
                    .ThenInclude(x => x.Locale)
                        .ThenInclude(x => x.Workers)
                .FirstOrDefaultAsync(x => x.Id == id);
            if (reservation == null)
            {
                throw new UserException("Rezervacija nije pronađena!");
            }

            if (!CanAccessReservation(reservation))
                throw new UserException("Nemate dozvolu za pregled ove rezervacije.");

            var state = GetStateMachine(reservation.ReservationState);
            return state.GetAllowedActions();
        }

        public async Task ProcessAutomaticTransitionsAsync(DateTime localNow)
        {
            var date = localNow.Date;
            var time = TimeOnly.FromDateTime(localNow);
            var overduePendingIds = await Context.Reservations
                .AsNoTracking()
                .Where(r =>
                    r.ReservationState == PendingReservationState.StateName &&
                    (r.ReservationDate.Date < date ||
                     (r.ReservationDate.Date == date && r.StartTime <= time)))
                .OrderBy(r => r.Id)
                .Select(r => r.Id)
                .ToListAsync();

            foreach (var id in overduePendingIds)
            {
                try
                {
                    var state = GetStateMachine(PendingReservationState.StateName);
                    await state.CancelBySystemAsync(
                        id,
                        "Automatski otkazana: nije potvrđena do termina");
                    _logger.LogInformation(
                        "Automatically cancelled overdue pending reservation {ReservationId}.",
                        id);
                }
                catch (InvalidOperationException ex)
                {
                    _logger.LogInformation(
                        ex,
                        "Skipped automatic cancellation for reservation {ReservationId} because its state changed.",
                        id);
                }
                catch (Exception ex)
                {
                    _logger.LogError(
                        ex,
                        "Error automatically cancelling reservation {ReservationId}. Skipping until next cycle.",
                        id);
                }
            }

            var overdueConfirmedIds = await Context.Reservations
                .AsNoTracking()
                .Where(r =>
                    r.ReservationState == ConfirmedReservationState.StateName &&
                    (r.ReservationDate.Date < date ||
                     (r.ReservationDate.Date == date && r.EndTime <= time)))
                .OrderBy(r => r.Id)
                .Select(r => r.Id)
                .ToListAsync();

            foreach (var id in overdueConfirmedIds)
            {
                try
                {
                    var state = GetStateMachine(ConfirmedReservationState.StateName);
                    await state.CompleteBySystemAsync(id);
                    _logger.LogInformation(
                        "Automatically completed overdue confirmed reservation {ReservationId}.",
                        id);
                }
                catch (InvalidOperationException ex)
                {
                    _logger.LogInformation(
                        ex,
                        "Skipped automatic completion for reservation {ReservationId} because its state changed.",
                        id);
                }
                catch (Exception ex)
                {
                    _logger.LogError(
                        ex,
                        "Error automatically completing reservation {ReservationId}. Skipping until next cycle.",
                        id);
                }
            }
        }

        private BaseReservationState GetStateMachine(string stateName)
        {
            return new BaseReservationState(Context, _mapper, _serviceProvider).GetReservationState(stateName);
        }
    }
}
