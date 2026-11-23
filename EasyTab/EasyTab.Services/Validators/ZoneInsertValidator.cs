using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class ZoneInsertValidator : AbstractValidator<ZoneInsertRequest>
    {
        public ZoneInsertValidator()
        {
            RuleFor(x => x.Name)
                .Cascade(CascadeMode.Stop)
                .NotEmpty().WithMessage(ZoneRules.NameRequired)
                .MaximumLength(ZoneRules.NameMaxLength).WithMessage(ZoneRules.NameTooLong);

            RuleFor(x => x.LocaleId)
                .GreaterThan(0).WithMessage(ZoneRules.LocaleRequired);

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
