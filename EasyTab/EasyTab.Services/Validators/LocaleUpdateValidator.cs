using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class LocaleUpdateValidator : AbstractValidator<LocaleUpdateRequest>
    {
        public LocaleUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(100).WithMessage("Naziv lokala ne može imati više od 100 karaktera.")
                .When(x => !string.IsNullOrEmpty(x.Name));

            RuleFor(x => x.Address)
                .MaximumLength(255).WithMessage("Adresa ne može imati više od 255 karaktera.")
                .When(x => !string.IsNullOrEmpty(x.Address));

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Broj telefona ne može imati više od 20 karaktera.")
                .Matches(@"^\+?[0-9\s\-]+$").WithMessage("Broj telefona nije ispravnog formata.")
                .When(x => !string.IsNullOrEmpty(x.PhoneNumber));

            RuleFor(x => x.CityId)
                .GreaterThan(0).WithMessage("Grad mora biti validan.")
                .When(x => x.CityId.HasValue);

            RuleFor(x => x.CategoryId)
                .GreaterThan(0).WithMessage("Kategorija mora biti validna.")
                .When(x => x.CategoryId.HasValue);

            RuleFor(x => x.LengthOfReservation)
                .GreaterThan(0).WithMessage("Trajanje rezervacije mora biti veće od 0.")
                .LessThanOrEqualTo(24).WithMessage("Trajanje rezervacije ne može biti duže od 24 sata.")
                .When(x => x.LengthOfReservation.HasValue);
        }
    }
}
