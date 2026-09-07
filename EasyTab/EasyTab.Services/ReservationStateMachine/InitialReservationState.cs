using EasyTab.Model.Messages;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Services.Database;
using EasyTab.Services.Interfaces;
using MapsterMapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace EasyTab.Services.ReservationStateMachine
{
    public class InitialReservationState : BaseReservationState
    {
        public InitialReservationState(_220030Context context, IMapper mapper, IServiceProvider serviceProvider)
            : base(context, mapper, serviceProvider)
        {
        }

        public override async Task<Reservations> CreateAsync(ReservationInsertRequest request)
        {
            var entity = _mapper.Map<Reservation>(request);
            entity.ReservationState = PendingReservationState.StateName;
            _context.Reservations.Add(entity);
            await _context.SaveChangesAsync();

            // Pripremi podatke za RabbitMQ poruku dok je DbContext još aktivan
            try
            {
                var user = await _context.Users.FindAsync(request.UserId);
                var table = await _context.Tables
                    .Include(t => t.Locale)
                    .FirstOrDefaultAsync(t => t.Id == request.TableId);

                if (user != null && table?.Locale != null)
                {
                    _context.Notifications.Add(new Notification
                    {
                        UserId = user.Id,
                        Title = "Rezervacija na čekanju",
                        Message = $"Vaša rezervacija za {table.Locale.Name} ({entity.ReservationDate:dd.MM.yyyy} u {entity.StartTime:HH:mm}) je kreirana i čeka potvrdu lokala.",
                        IsRead = false,
                        CreatedAt = DateTime.UtcNow
                    });
                    await _context.SaveChangesAsync();

                    var message = new ReservationCreatedMessage
                    {
                        ReservationId = entity.Id,
                        UserId = user.Id,
                        UserEmail = user.Email,
                        UserFullName = $"{user.FirstName} {user.LastName}",
                        LocaleName = table.Locale.Name,
                        ReservationDate = entity.ReservationDate,
                        StartTime = entity.StartTime.ToString("HH:mm"),
                        EndTime = entity.EndTime.ToString("HH:mm"),
                        NumberOfGuests = table.NumberOfGuests
                    };

                    var publisher = _serviceProvider.GetRequiredService<IRabbitMQPublisher>();
                    _ = Task.Run(async () =>
                    {
                        try
                        {
                            await publisher.PublishReservationCreatedAsync(message);
                        }
                        catch { /* publish greška ne blokira API */ }
                    });
                }
            }
            catch { /* greška ne blokira kreiranje rezervacije */ }

            return _mapper.Map<Reservations>(entity);
        }

        public override List<string> GetAllowedActions()
        {
            return new List<string> { "Create" };
        }
    }
}
