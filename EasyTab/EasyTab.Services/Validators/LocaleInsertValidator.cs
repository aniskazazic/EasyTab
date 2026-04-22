using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class LocaleInsertValidator : AbstractValidator<LocaleInsertRequest>
    {
        public LocaleInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv lokala je obavezan.")
                .MaximumLength(100).WithMessage("Naziv lokala ne može imati više od 100 karaktera.");

            RuleFor(x => x.Address)
                .NotEmpty().WithMessage("Adresa je obavezna.")
                .MaximumLength(255).WithMessage("Adresa ne može imati više od 255 karaktera.");

            RuleFor(x => x.CityId)
                .GreaterThan(0).WithMessage("Grad je obavezan.");

            RuleFor(x => x.CategoryId)
                .GreaterThan(0).WithMessage("Kategorija je obavezna.");

            RuleFor(x => x.OwnerId)
                .GreaterThan(0).WithMessage("Vlasnik je obavezan.");

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Broj telefona ne može imati više od 20 karaktera.")
                .Matches(@"^\+?[0-9\s\-]+$").WithMessage("Broj telefona nije ispravnog formata.")
                .When(x => !string.IsNullOrEmpty(x.PhoneNumber));

            RuleFor(x => x.StartOfWorkingHours)
                .NotEmpty().WithMessage("Početak radnog vremena je obavezno.");

            RuleFor(x => x.EndOfWorkingHours)
                .NotEmpty().WithMessage("Kraj radnog vremena je obavezan.");

            RuleFor(x => x.LengthOfReservation)
                .GreaterThan(0).WithMessage("Trajanje rezervacije mora biti veće od 0.");

        }
    }
}
