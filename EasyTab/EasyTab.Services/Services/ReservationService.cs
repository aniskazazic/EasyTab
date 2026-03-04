using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Implementation;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
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
        public ReservationService(_220030Context context, IMapper mapper, IWebHostEnvironment wh) : base(context, mapper)
        {
            _wh = wh;
        }

        public override IQueryable<Reservation> AddFilter(IQueryable<Reservation> query, ReservationSearchObject search)
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
                    (r.ReservationDate == now.Date && r.StartTime > now.TimeOfDay));
            }
            // Prošle rezervacije
            else if (search?.IsUpcoming == false)
            {
                var now = DateTime.Now;
                query = query.Where(r =>
                    r.ReservationDate < now.Date ||
                    (r.ReservationDate == now.Date && r.StartTime < now.TimeOfDay));
            }

            return query;
        }

        public override void BeforeInsert(ReservationInsertRequest request, Reservation entity)
        {
            // Provjeri overlap
            var overlaps = Context.Reservations.Any(r =>
                r.TableId == request.TableId &&
                r.ReservationDate.Date == request.ReservationDate.Date &&
                r.IsCancelled == false &&
                r.StartTime < TimeOnly.FromTimeSpan(request.EndTime) &&
                TimeOnly.FromTimeSpan(request.StartTime) < r.EndTime);

            if (overlaps)
                throw new Exception("Stol je već rezervisan za ovaj termin!");

            entity.CreatedAt = DateTime.Now;
            entity.IsCancelled = false;
        }

        public List<TimeSlots> GetAvailableSlots(int tableId, DateTime date)
        {
            var locale = Context.Tables
                .Include(x => x.Locale)
                .Where(x => x.Id == tableId)
                .FirstOrDefault()?.Locale;

            if (locale == null)
                throw new Exception("Lokal nije pronađen!");

            var open = locale.StartOfWorkingHours.ToTimeSpan();
            var close = locale.EndOfWorkingHours.ToTimeSpan();
            var slotLength = TimeSpan.FromHours(locale.LengthOfReservation != 0 ? locale.LengthOfReservation : 2);

            // Generiši sve slotove
            var allSlots = new List<(TimeSpan Start, TimeSpan End)>();
            for (var t = open; t + slotLength <= close; t += slotLength)
                allSlots.Add((t, t + slotLength));

            // Dohvati zauzete termine
            var reserved = Context.Reservations
                .Where(r => r.TableId == tableId &&
                            r.ReservationDate.Date == date.Date &&
                            r.IsCancelled == false)
                .Select(r => new { r.StartTime, r.EndTime })
                .ToList();

            var now = DateTime.Now;

            // Filtriraj slobodne slotove
            return allSlots
                .Where(slot =>
                    !reserved.Any(res =>
                        slot.Start < res.EndTime.ToTimeSpan() && res.StartTime.ToTimeSpan() < slot.End) &&
                    date.Date.Add(slot.Start) > now)
                .Select(s => new TimeSlots
                {
                    Start = s.Start.ToString(@"hh\:mm"),
                    End = s.End.ToString(@"hh\:mm")
                })
                .ToList();
        }

        public void CancelReservation(int id)
        {
            var reservation = Context.Reservations.Find(id);
            if (reservation == null)
                throw new Exception("Rezervacija nije pronađena!");

            reservation.IsCancelled = true;
            Context.SaveChanges();
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
    }
}
