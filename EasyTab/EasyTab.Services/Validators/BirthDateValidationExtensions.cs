using FluentValidation;

namespace EasyTab.Services.Validators;

public static class BirthDateValidationExtensions
{
    public static IRuleBuilderOptions<T, DateTime?> ValidBirthDate<T>(
        this IRuleBuilder<T, DateTime?> rule) => rule
        .Must(date => !date.HasValue || date.Value.Date > new DateTime(1900, 1, 1))
        .WithMessage("Datum rođenja mora biti nakon 01.01.1900.")
        .Must(date => !date.HasValue || date.Value.Date <= LocalClock.Now.Date)
        .WithMessage("Datum rođenja ne može biti u budućnosti.")
        .Must(date => !date.HasValue || date.Value.Date <= LocalClock.Now.Date.AddYears(-18))
        .WithMessage("Korisnik mora imati najmanje 18 godina.");
}
