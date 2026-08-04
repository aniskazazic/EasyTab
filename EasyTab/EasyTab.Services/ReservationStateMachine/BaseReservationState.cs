using EasyTab.Model.Exceptions;
using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Services.Database;
using MapsterMapper;
using Microsoft.Extensions.DependencyInjection;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace EasyTab.Services.ReservationStateMachine
{
    public class BaseReservationState
    {
        protected _220030Context _context { get; set; }
        protected IMapper _mapper { get; set; }
        protected IServiceProvider _serviceProvider { get; set; }

        public BaseReservationState(_220030Context context, IMapper mapper, IServiceProvider serviceProvider)
        {
            _context = context;
            _mapper = mapper;
            _serviceProvider = serviceProvider;
        }

        public virtual Task<Reservations> CreateAsync(ReservationInsertRequest request)
        {
            throw new InvalidOperationException("Cannot create a reservation in its current state.");
        }

        public virtual Task<Reservations> UpdateAsync(int id, ReservationUpdateRequest request)
        {
            throw new InvalidOperationException("Cannot update a reservation in its current state.");
        }

        public virtual Task<Reservations> ConfirmAsync(int id, int approvedById)
        {
            throw new InvalidOperationException("Cannot confirm a reservation in its current state.");
        }

        public virtual Task<Reservations> CancelAsync(int id, string reason, int cancelledById)
        {
            throw new InvalidOperationException("Cannot cancel a reservation in its current state.");
        }

        public virtual Task<Reservations> CompleteAsync(int id)
        {
            throw new InvalidOperationException("Cannot complete a reservation in its current state.");
        }

        public virtual List<string> GetAllowedActions()
        {
            return new List<string>();
        }

        protected async Task<Reservation> GetReservationOrThrowAsync(int id)
        {
            var entity = await _context.Reservations.FindAsync(id);
            if (entity == null)
            {
                throw new KeyNotFoundException($"Reservation with id {id} not found.");
            }

            return entity;
        }

        public BaseReservationState GetReservationState(string stateName)
        {
            switch (stateName)
            {
                case "Na čekanju":
                case "Pending":
                case nameof(PendingReservationState):
                    return _serviceProvider.GetService<PendingReservationState>()!;
                case nameof(InitialReservationState):
                    return _serviceProvider.GetService<InitialReservationState>()!;
                case "Potvrđena":
                case "Confirmed":
                case nameof(ConfirmedReservationState):
                    return _serviceProvider.GetService<ConfirmedReservationState>()!;
                case "Otkazana":
                case "Cancelled":
                case nameof(CancelledReservationState):
                    return _serviceProvider.GetService<CancelledReservationState>()!;
                case "Završena":
                case "Completed":
                case nameof(CompletedReservationState):
                    return _serviceProvider.GetService<CompletedReservationState>()!;
                default:
                    throw new UserException("State not recognized");
            }
        }
    }
}
