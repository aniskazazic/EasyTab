using EasyTab.Model.Requests;
using EasyTab.Model.Serialization;
using EasyTab.Services.Database;
using FluentValidation;
using Microsoft.EntityFrameworkCore;

namespace EasyTab.Services.Validators
{
    public class LocaleInsertValidator : AbstractValidator<LocaleInsertRequest>
    {
        public LocaleInsertValidator(_220030Context context)
        {
            RuleFor(x => x.Logo)
                .Must((request, logo) => string.IsNullOrEmpty(logo) ||
                    ImageContentValidator.IsValidImageUpload(logo, request.LogoFileName, request.LogoContentType))
                .WithMessage(ImageContentValidator.ErrorMessage);

            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv lokala je obavezan.")
                .MaximumLength(100).WithMessage("Naziv lokala ne može imati više od 100 karaktera.");

            RuleFor(x => x.Address)
                .NotEmpty().WithMessage("Adresa je obavezna.")
                .MaximumLength(255).WithMessage("Adresa ne može imati više od 255 karaktera.");

            RuleFor(x => x.CountryId)
                .Cascade(CascadeMode.Stop)
                .GreaterThan(0).WithMessage("Država je obavezna.")
                .MustAsync((countryId, cancellationToken) => context.Countries
                    .AnyAsync(country => country.Id == countryId, cancellationToken))
                .WithMessage("Odabrana država ne postoji.");

            RuleFor(x => x.CityId)
                .Cascade(CascadeMode.Stop)
                .GreaterThan(0).WithMessage("Grad je obavezan.")
                .MustAsync((request, cityId, cancellationToken) => context.Cities
                    .AnyAsync(city => city.Id == cityId && city.CountryId == request.CountryId, cancellationToken))
                .WithMessage("Odabrani grad mora pripadati odabranoj državi.");

            RuleFor(x => x.CategoryId)
                .GreaterThan(0).WithMessage("Kategorija je obavezna.");

            RuleFor(x => x.OwnerId)
                .GreaterThan(0).WithMessage("Vlasnik je obavezan.");

            RuleFor(x => x.PhoneNumber)
                .NotEmpty().WithMessage("Broj telefona je obavezan.")
                .MaximumLength(20).WithMessage("Broj telefona ne može imati više od 20 karaktera.")
                .Matches(@"^\+?[0-9\s\-]+$").WithMessage("Broj telefona nije ispravnog formata.");

            RuleFor(x => x.StartOfWorkingHours)
                .NotNull().WithMessage("Početak radnog vremena je obavezan.");

            RuleFor(x => x.EndOfWorkingHours)
                .NotNull().WithMessage("Kraj radnog vremena je obavezan.");

            RuleFor(x => x.LengthOfReservation)
                .Must(value => double.IsFinite(value) && value >= 0.5 && value <= 24 && value * 2 == Math.Truncate(value * 2))
                .WithMessage(ReservationDurationMessages.InvalidValue);

            RuleFor(x => x.ReservationPrice)
                .GreaterThanOrEqualTo(1m).WithMessage("Cijena rezervacije mora biti najmanje 1 KM.")
                .LessThanOrEqualTo(100m).WithMessage("Cijena rezervacije ne može biti veća od 100 KM.")
                .Must(price => decimal.Round(price, 2) == price).WithMessage("Cijena rezervacije može imati najviše 2 decimale.");
        }
    }
}
