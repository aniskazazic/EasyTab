using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class RoleInsertValidator : AbstractValidator<RoleInsertRequest>
    {
        public RoleInsertValidator()
        {
            RuleFor(x => x.Name)
           .NotEmpty().WithMessage("Ime role je obavezno.")
           .MaximumLength(100).WithMessage("Ime role ne može imati više od 100 karaktera.");

            RuleFor(x => x.Description)
                .NotEmpty().WithMessage("Opis role je obavezan.")
                .MaximumLength(100).WithMessage("Opis role ne može imati više od 100 karaktera.");
        }
    }
}
