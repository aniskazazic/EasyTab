using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class ZoneInsertValidator : AbstractValidator<ZoneInsertRequest>
    {
        public ZoneInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv zone je obavezan.")
                .MaximumLength(50).WithMessage("Naziv zone ne može imati više od 50 karaktera.");

            RuleFor(x => x.LocaleId)
                .GreaterThan(0).WithMessage("Lokal je obavezan.");

            RuleFor(x => x.Width)
                .GreaterThan(0).WithMessage("Širina zone mora biti veća od 0.");

            RuleFor(x => x.Height)
                .GreaterThan(0).WithMessage("Visina zone mora biti veća od 0.");

            RuleFor(x => x.XCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage("X koordinata mora biti pozitivna.");

            RuleFor(x => x.YCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage("Y koordinata mora biti pozitivna.");
        }
    }
}
