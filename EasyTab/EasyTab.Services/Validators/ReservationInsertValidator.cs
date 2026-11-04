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
                .GreaterThanOrEqualTo(_ => LocalClock.Now.Date)
                .WithMessage("Datum rezervacije ne može biti u prošlosti.");

            RuleFor(x => x.StartTime)
                .Must(time => time >= TimeSpan.Zero && time < TimeSpan.FromDays(1))
                .WithMessage("Početak rezervacije mora biti između 00:00 i 23:59.");

            RuleFor(x => x.EndTime)
                .Must(time => time >= TimeSpan.Zero && time < TimeSpan.FromDays(1))
                .WithMessage("Kraj rezervacije mora biti između 00:00 i 23:59.")
                .NotEqual(x => x.StartTime)
                .WithMessage("Početak i kraj rezervacije ne mogu biti isti.");
        }
    }
}
