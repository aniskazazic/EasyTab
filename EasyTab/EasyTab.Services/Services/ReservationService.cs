using EasyTab.Model.Models;
using EasyTab.Model.Exceptions;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using EasyTab.Services.ReservationStateMachine;
using FluentValidation;
using MapsterMapper;
using Microsoft.AspNetCore.Hosting;
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
        private readonly IWebHostEnvironment _wh;
        private readonly ILogger<ReservationService> _logger;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILocaleAccessService _localeAccessService;
        private readonly ICurrentUserService _currentUser;

        public ReservationService(_220030Context context, IMapper mapper, IWebHostEnvironment wh, ILogger<ReservationService> logger, IServiceProvider serviceProvider, IValidator<ReservationInsertRequest> insertValidator, IValidator<ReservationUpdateRequest> updateValidator, ILocaleAccessService localeAccessService, ICurrentUserService currentUser) : base(context, mapper, insertValidator, updateValidator)
        {
            _wh = wh;
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
            else if (_currentUser.Role == "Vlasnik")
            {
                query = query.Where(x => x.Table.Locale.OwnerId == _currentUser.UserId);
            }
            else if (_currentUser.Role == "Radnik")
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

            if (search?.ReservationState != null)
                query = query.Where(x => x.ReservationState == search.ReservationState);

            // Aktivne rezervacije: samo one koje nisu otkazane/završene i čiji termin još nije prošao
            if (search?.IsUpcoming == true)
            {
                var now = DateTime.Now;
                query = query.Where(r =>
                    r.ReservationState != CancelledReservationState.StateName &&
                    r.ReservationState != CompletedReservationState.StateName &&
                    (r.ReservationDate.Date > now.Date ||
                    (r.ReservationDate.Date == now.Date && r.StartTime >= TimeOnly.FromTimeSpan(now.TimeOfDay))));
            }
            // Prošle / historija rezervacije: otkazane, završene ili one čiji je termin prošao
            else if (search?.IsUpcoming == false)
            {
                var now = DateTime.Now;
                query = query.Where(r =>
                    r.ReservationState == CancelledReservationState.StateName ||
                    r.ReservationState == CompletedReservationState.StateName ||
                    r.ReservationDate.Date < now.Date ||
                    (r.ReservationDate.Date == now.Date && r.StartTime < TimeOnly.FromTimeSpan(now.TimeOfDay)));
            }

            // Po defaultu najnovije rezervacije na vrhu
            if (string.IsNullOrWhiteSpace(search?.SortBy))
            {
                query = query.OrderByDescending(x => x.ReservationDate)
                             .ThenByDescending(x => x.StartTime);
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

            return MapToResponse(entity);
        }

        private bool CanAccessReservation(Reservation reservation)
        {
            if (_currentUser.IsAdmin)
                return true;

            if (_currentUser.Role == "Vlasnik")
                return reservation.Table.Locale.OwnerId == _currentUser.UserId;

            if (_currentUser.Role == "Radnik")
                return reservation.Table.Locale.Workers.Any(worker =>
                    worker.UserId == _currentUser.UserId && !worker.IsDeleted);

            return reservation.UserId == _currentUser.UserId;
        }

        protected override async Task BeforeInsert(Reservation entity, ReservationInsertRequest request)
        {
            _logger.LogInformation("Creating reservation. UserId: {UserId}, TableId: {TableId}, ReservationDate: {ReservationDate}", request.UserId, request.TableId, request.ReservationDate);

            var table = await Context.Tables.FindAsync(request.TableId);
            if (table == null)
            {
                throw new UserException("Stol nije pronađen!");
            }

            if (request.NumberOfGuests != table.NumberOfGuests)
            {
                throw new UserException($"Stol prima tačno {table.NumberOfGuests} gostiju.");
            }

            var duplicate = await Context.Reservations.AnyAsync(r =>
                r.UserId == request.UserId &&
                r.TableId == request.TableId &&
                r.ReservationDate.Date == request.ReservationDate.Date &&
                r.StartTime == TimeOnly.FromTimeSpan(request.StartTime) &&
                r.ReservationState != CancelledReservationState.StateName);

            if (duplicate)
            {
                throw new UserException("Već imate rezervaciju za ovaj stol u ovom terminu!");
            }

            var overlaps = await Context.Reservations.AnyAsync(r =>
                r.TableId == request.TableId &&
                r.ReservationDate.Date == request.ReservationDate.Date &&
                r.ReservationState != CancelledReservationState.StateName &&
                r.StartTime < TimeOnly.FromTimeSpan(request.EndTime) &&
                TimeOnly.FromTimeSpan(request.StartTime) < r.EndTime);

            if (overlaps)
            {
                _logger.LogWarning("Reservation overlap detected. TableId: {TableId}, ReservationDate: {ReservationDate}", request.TableId, request.ReservationDate);
                throw new UserException("Stol je već rezervisan za ovaj termin!");
            }

            entity.CreatedAt = DateTime.Now;
            entity.ReservationState = PendingReservationState.StateName;

            await Task.CompletedTask;
        }

        public List<TimeSlots> GetAvailableSlots(int tableId, DateTime date)
        {
            var locale = Context.Tables
                .Include(x => x.Locale)
                .Where(x => x.Id == tableId)
                .FirstOrDefault()?.Locale;

            if (locale == null)
            {
                _logger.LogWarning("Cannot fetch available slots because locale was not found. TableId: {TableId}", tableId);
                throw new UserException("Lokal nije pronađen!");
            }

            var open = locale.StartOfWorkingHours.ToTimeSpan();
            var close = locale.EndOfWorkingHours.ToTimeSpan();

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

            var slotHours = (locale.LengthOfReservation > 0) ? locale.LengthOfReservation : 2.0;
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
                .ToList();

            var now = DateTime.Now;

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
                    !reserved.Any(res =>
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

            if (_currentUser.Role == "Vlasnik" || _currentUser.Role == "Radnik" || _currentUser.IsAdmin)
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

        // Vraća logo kao base64
        private async Task<string> GetLogoBase64(string? logo, CancellationToken cancellationToken)
        {
            if (string.IsNullOrEmpty(logo)) return "";

            string logoPath = Path.Combine(_wh.WebRootPath, "images", "locales", logo);
            if (!File.Exists(logoPath)) return "";

            byte[] imageBytes = await File.ReadAllBytesAsync(logoPath, cancellationToken);
            return $"data:image/png;base64,{Convert.ToBase64String(imageBytes)}";
        }

        public override async Task<Reservations> CreateAsync(ReservationInsertRequest request)
        {
            request.UserId = _currentUser.UserId;
            var initialState = GetStateMachine(nameof(InitialReservationState));
            return await initialState.CreateAsync(request);
        }

        public async Task<Reservations> ActivateAsync(int id)
        {
            var reservation = await Context.Reservations.FindAsync(id);
            if (reservation == null)
            {
                throw new UserException("Rezervacija nije pronađena!");
            }

            var state = GetStateMachine(reservation.ReservationState);
            return await state.ConfirmAsync(id, reservation.UserId);
        }

        public async Task<Reservations> DeactivateAsync(int id)
        {
            var reservation = await Context.Reservations.FindAsync(id);
            if (reservation == null)
            {
                throw new UserException("Rezervacija nije pronađena!");
            }

            var state = GetStateMachine(reservation.ReservationState);
            return await state.CompleteAsync(id);
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

        private BaseReservationState GetStateMachine(string stateName)
        {
            return new BaseReservationState(Context, _mapper, _serviceProvider).GetReservationState(stateName);
        }
    }
}
