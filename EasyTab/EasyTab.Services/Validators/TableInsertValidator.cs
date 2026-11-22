using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class TableInsertValidator : AbstractValidator<TableInsertRequest>
    {
        public TableInsertValidator()
        {
            RuleFor(x => x.Name)
                .Cascade(CascadeMode.Stop)
                .NotEmpty().WithMessage(TableRules.NameRequired)
                .MaximumLength(TableRules.NameMaxLength).WithMessage(TableRules.NameTooLong);

            RuleFor(x => x.LocaleId)
                .GreaterThan(0).WithMessage(TableRules.LocaleRequired);

            RuleFor(x => x.NumberOfGuests)
                .InclusiveBetween(TableRules.MinGuests, TableRules.MaxGuests).WithMessage(TableRules.GuestsOutOfRange);

            RuleFor(x => x.XCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage(TableRules.XCoordinateNegative);

            RuleFor(x => x.YCoordinate)
                .GreaterThanOrEqualTo(0).WithMessage(TableRules.YCoordinateNegative);
        }
    }
}
