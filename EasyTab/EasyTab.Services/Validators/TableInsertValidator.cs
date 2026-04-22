using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class TableInsertValidator : AbstractValidator<TableInsertRequest>
    {
        public TableInsertValidator()
        {
            RuleFor(x => x.Name)
                .NotEmpty().WithMessage("Naziv stola je obavezan.")
                .MaximumLength(50).WithMessage("Naziv stola ne može imati više od 50 karaktera.");

            RuleFor(x => x.LocaleId)
                .GreaterThan(0).WithMessage("Lokal je obavezan.");

            RuleFor(x => x.NumberOfGuests)
                .InclusiveBetween(1, 8).WithMessage("Broj gostiju mora biti između 1 i 8.");

            RuleFor(x => x.XCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage("X koordinata mora biti pozitivna.");

            RuleFor(x => x.YCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage("Y koordinata mora biti pozitivna.");
        }
    }
}
