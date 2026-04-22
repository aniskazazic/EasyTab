using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class ZoneUpdateValidator : AbstractValidator<ZoneUpdateRequest>
    {
        public ZoneUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(50).WithMessage("Naziv zone ne može imati više od 50 karaktera.")
                .When(x => !string.IsNullOrEmpty(x.Name));

            RuleFor(x => x.Width)
                .GreaterThan(0).WithMessage("Širina zone mora biti veća od 0.")
                .When(x => x.Width.HasValue);

            RuleFor(x => x.Height)
                .GreaterThan(0).WithMessage("Visina zone mora biti veća od 0.")
                .When(x => x.Height.HasValue);

            RuleFor(x => x.XCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage("X koordinata mora biti pozitivna.")
                .When(x => x.XCoordinate.HasValue);

            RuleFor(x => x.YCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage("Y koordinata mora biti pozitivna.")
                .When(x => x.YCoordinate.HasValue);
        }
    }
}
