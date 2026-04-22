using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class ReservationInsertValidator : AbstractValidator<ReservationInsertRequest>
    {
        public ReservationInsertValidator()
        {
            RuleFor(x => x.TableId)
                .GreaterThan(0).WithMessage("Stol je obavezan.");

            RuleFor(x => x.UserId)
                .GreaterThan(0).WithMessage("Korisnik je obavezan.");

            RuleFor(x => x.ReservationDate)
                .NotEmpty().WithMessage("Datum rezervacije je obavezan.")
                .GreaterThanOrEqualTo(DateTime.Today)
                .WithMessage("Datum rezervacije ne može biti u prošlosti.");

            RuleFor(x => x.StartTime)
                .NotEmpty().WithMessage("Početak rezervacije je obavezan.");
        }
    }
}
