using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class ReviewUpdateValidator : AbstractValidator<ReviewUpdateRequest>
    {
        public ReviewUpdateValidator()
        {
            RuleFor(x => x.Description)
               .MaximumLength(1000).WithMessage("Opis recenzije ne može imati više od 1000 karaktera.")
               .When(x => !string.IsNullOrEmpty(x.Description));

            RuleFor(x => x.Rating)
                .InclusiveBetween(1, 5).WithMessage("Ocjena mora biti između 1 i 5.")
                .When(x => x.Rating.HasValue);
        }
    }
}
