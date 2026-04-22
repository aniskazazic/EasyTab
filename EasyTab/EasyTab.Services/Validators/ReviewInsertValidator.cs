using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class ReviewInsertValidator : AbstractValidator<ReviewInsertRequest>
    {
        public ReviewInsertValidator()
        {
            RuleFor(x => x.Description)
                .NotEmpty().WithMessage("Opis recenzije je obavezan.")
                .MaximumLength(1000).WithMessage("Opis recenzije ne može imati više od 1000 karaktera.");

            RuleFor(x => x.Rating)
                .InclusiveBetween(1, 5).WithMessage("Ocjena mora biti između 1 i 5.");

            RuleFor(x => x.LocaleId)
                .GreaterThan(0).WithMessage("Lokal je obavezan.");

            RuleFor(x => x.UserId)
                .GreaterThan(0).WithMessage("Korisnik je obavezan.");
        }
    }
}
