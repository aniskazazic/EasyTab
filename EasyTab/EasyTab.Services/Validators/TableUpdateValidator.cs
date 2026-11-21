using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class TableUpdateValidator : AbstractValidator<TableUpdateRequest>
    {
        public TableUpdateValidator()
        {
            RuleFor(x => x.Name)
                .Cascade(CascadeMode.Stop)
                .NotEmpty().WithMessage(TableRules.NameRequired)
                .MaximumLength(TableRules.NameMaxLength).WithMessage(TableRules.NameTooLong)
                .When(x => x.Name != null);

            RuleFor(x => x.NumberOfGuests)
                .InclusiveBetween(TableRules.MinGuests, TableRules.MaxGuests).WithMessage(TableRules.GuestsOutOfRange)
                .When(x => x.NumberOfGuests.HasValue);

            RuleFor(x => x.XCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage(TableRules.XCoordinateNegative)
                .When(x => x.XCoordinate.HasValue);

            RuleFor(x => x.YCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage(TableRules.YCoordinateNegative)
                .When(x => x.YCoordinate.HasValue);
        }
    }
}
