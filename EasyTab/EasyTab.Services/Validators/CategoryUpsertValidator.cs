using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class CategoryUpsertValidator : AbstractValidator<CategoryUpsertRequest>
    {
        public CategoryUpsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv kategorije je obavezan.")
                .MaximumLength(100).WithMessage("Naziv kategorije ne može imati više od 100 karaktera.");
        
        RuleFor(x => x.Description)
                .NotEmpty().WithMessage("Opis je obavezan.")
                .MaximumLength(500).WithMessage("Opis ne može imati više od 500 karaktera.")
                .When(x => !string.IsNullOrEmpty(x.Description));
        }
    }
}
