using EasyTab.Model.Requests;
using EasyTab.Model.Serialization;
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
                .GreaterThan(0)
                .LessThanOrEqualTo(24)
                .WithMessage(ReservationDurationMessages.InvalidValue)
                .When(x => x.LengthOfReservation.HasValue);

            RuleFor(x => x.ReservationPrice!.Value)
                .GreaterThan(0).WithMessage("Cijena rezervacije mora biti veća od 0.")
                .Must(price => decimal.Round(price, 2) == price).WithMessage("Cijena rezervacije može imati najviše 2 decimale.")
                .When(x => x.ReservationPrice.HasValue);
        }
    }
}
