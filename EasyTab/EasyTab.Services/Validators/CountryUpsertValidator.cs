using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class CountryUpsertValidator : AbstractValidator<CountryUpsertRequest>
    {
        public CountryUpsertValidator()
        {
            RuleFor(x => x.Name)
                 .NotEmpty().WithMessage("Naziv države je obavezan.")
                 .MaximumLength(100).WithMessage("Naziv države ne može imati više od 100 karaktera.");
        }
    }
}
