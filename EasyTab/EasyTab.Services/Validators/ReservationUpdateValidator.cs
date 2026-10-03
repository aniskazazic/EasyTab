using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class ReservationUpdateValidator : AbstractValidator<ReservationUpdateRequest>
    {
        public ReservationUpdateValidator()
        {
        }
    }
}
