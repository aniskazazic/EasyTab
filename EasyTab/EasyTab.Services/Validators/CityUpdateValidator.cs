using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class CityUpdateValidator : AbstractValidator<CityUpdateRequest>
    {
        public CityUpdateValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv grada je obavezan.")
                .MaximumLength(100).WithMessage("Naziv grada ne može imati više od 100 karaktera.");

            RuleFor(x => x.CountryId)
                .GreaterThan(0).WithMessage("Država je obavezna.");
        }
    }
}
