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
        void CancelReservation(int id);
    }
}
