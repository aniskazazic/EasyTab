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

        public ReservationService(_220030Context context, IMapper mapper, IWebHostEnvironment wh, ILogger<ReservationService> logger, IServiceProvider serviceProvider, IValidator<ReservationInsertRequest> insertValidator, IValidator<ReservationUpdateRequest> updateValidator) : base(context, mapper, insertValidator, updateValidator)
        {
            _wh = wh;
            _logger = logger;
            _serviceProvider = serviceProvider;
        }

        protected override IQueryable<Reservation> ApplyFilter(IQueryable<Reservation> query, ReservationSearchObject search)
        {
            query = query.Include(r => r.Table)
                                      .ThenInclude(t => t.Locale);

            if (search?.UserId.HasValue == true)
                query = query.Where(x => x.UserId == search.UserId);

            if (search?.TableId.HasValue == true)
                query = query.Where(x => x.TableId == search.TableId);

            if (search?.LocaleId.HasValue == true)
                query = query.Where(x => x.Table.LocaleId == search.LocaleId);

            if (search?.IsCancelled.HasValue == true)
                query = query.Where(x => x.IsCancelled == search.IsCancelled);

            // Aktivne rezervacije
            if (search?.IsUpcoming == true)
            {
                var now = DateTime.Now;
                query = query.Where(r =>
                    r.ReservationDate > now.Date ||
                    (r.ReservationDate == now.Date && r.StartTime > TimeOnly.FromTimeSpan(now.TimeOfDay)));
            }
            // Prošle rezervacije
            else if (search?.IsUpcoming == false)
            {
                var now = DateTime.Now;
                query = query.Where(r =>
                    r.ReservationDate < now.Date ||
                    (r.ReservationDate == now.Date && r.StartTime < TimeOnly.FromTimeSpan(now.TimeOfDay)));
            }

            return query;
        }

        protected override async Task BeforeInsert(Reservation entity, ReservationInsertRequest request)
        {
            _logger.LogInformation("Creating reservation. UserId: {UserId}, TableId: {TableId}, ReservationDate: {ReservationDate}", request.UserId, request.TableId, request.ReservationDate);

            var overlaps = Context.Reservations.Any(r =>
                r.TableId == request.TableId &&
                r.ReservationDate.Date == request.ReservationDate.Date &&
                r.IsCancelled == false &&
                r.StartTime < TimeOnly.FromTimeSpan(request.EndTime) &&
                TimeOnly.FromTimeSpan(request.StartTime) < r.EndTime);

            if (overlaps)
            {
                _logger.LogWarning("Reservation overlap detected. TableId: {TableId}, ReservationDate: {ReservationDate}", request.TableId, request.ReservationDate);
                throw new UserException("Stol je već rezervisan za ovaj termin!");
            }

            entity.CreatedAt = DateTime.Now;
            entity.IsCancelled = false;

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
                            r.IsCancelled == false)
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

        public void CancelReservation(int id)
        {
            CancelReservationAsync(id).GetAwaiter().GetResult();
        }

        public async Task CancelReservationAsync(int id)
        {
            _logger.LogWarning("Cancelling reservation. ReservationId: {ReservationId}", id);
            var reservation = await Context.Reservations.FindAsync(id);
            if (reservation == null)
            {
                _logger.LogWarning("Cannot cancel reservation because it was not found. ReservationId: {ReservationId}", id);
                throw new UserException("Rezervacija nije pronađena!");
            }

            var state = GetStateMachine(reservation.ReservationState);
            await state.CancelAsync(id);
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
            return await state.ConfirmAsync(id);
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
            var reservation = await Context.Reservations.FindAsync(id);
            if (reservation == null)
            {
                throw new UserException("Rezervacija nije pronađena!");
            }

            var state = GetStateMachine(reservation.ReservationState);
            return await state.ConfirmAsync(id);
        }

        public async Task<Reservations> CompleteAsync(int id)
        {
            var reservation = await Context.Reservations.FindAsync(id);
            if (reservation == null)
            {
                throw new UserException("Rezervacija nije pronađena!");
            }

            var state = GetStateMachine(reservation.ReservationState);
            return await state.CompleteAsync(id);
        }

        public Task<List<string>> GetAllowedActionsAsync(int id)
        {
            var reservation = Context.Reservations.Find(id);
            if (reservation == null)
            {
                throw new UserException("Rezervacija nije pronađena!");
            }

            var state = GetStateMachine(reservation.ReservationState);
            return Task.FromResult(state.GetAllowedActions());
        }

        private BaseReservationState GetStateMachine(string stateName)
        {
            return new BaseReservationState(Context, _mapper, _serviceProvider).GetReservationState(stateName);
        }
    }
}
