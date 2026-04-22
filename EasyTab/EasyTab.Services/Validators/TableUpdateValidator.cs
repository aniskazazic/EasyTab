using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class TableUpdateValidator : AbstractValidator<TableUpdateRequest>
    {
        public TableUpdateValidator()
        {
            RuleFor(x => x.Name)
                .MaximumLength(50).WithMessage("Naziv stola ne može imati više od 50 karaktera.")
                .When(x => !string.IsNullOrEmpty(x.Name));

            RuleFor(x => x.NumberOfGuests)
                .InclusiveBetween(1, 8).WithMessage("Broj gostiju mora biti između 1 i 8.")
                .When(x => x.NumberOfGuests.HasValue);

            RuleFor(x => x.XCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage("X koordinata mora biti pozitivna.")
                .When(x => x.XCoordinate.HasValue);

            RuleFor(x => x.YCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage("Y koordinata mora biti pozitivna.")
                .When(x => x.YCoordinate.HasValue);
        }
    }
}
