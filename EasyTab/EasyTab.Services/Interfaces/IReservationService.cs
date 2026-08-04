using EasyTab.Model.Models;
using EasyTab.Model.Requests;
using EasyTab.Model.SearchObjects;
using EasyTab.Services.BaseServices.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Interfaces
{
    public interface IReservationService : ICRUDService<Reservations, ReservationSearchObject, ReservationInsertRequest, ReservationUpdateRequest>
    {
        List<TimeSlots> GetAvailableSlots(int tableId, DateTime date);
        void CancelReservation(int id, string reason, int cancelledById);
        Task CancelReservationAsync(int id, string reason, int cancelledById);

        Task<Reservations> ActivateAsync(int id);
        Task<Reservations> DeactivateAsync(int id);
        Task<Reservations> ConfirmAsync(int id, int approvedById);
        Task<Reservations> CompleteAsync(int id);
        Task<List<string>> GetAllowedActionsAsync(int id);
    }
}
