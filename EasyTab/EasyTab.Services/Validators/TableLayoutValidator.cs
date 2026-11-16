using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class TableLayoutValidator : AbstractValidator<TableLayoutRequest>
    {
        public TableLayoutValidator()
        {
            RuleFor(x => x.LocaleId)
                .GreaterThan(0).WithMessage(TableRules.LocaleRequired);

            // Zahtjev bez liste stolova odbija već model binding (polje nije nullable), pa ovdje lista uvijek postoji.
            RuleFor(x => x.Tables)
                .Custom(ValidateTables);
        }

        // Ista pravila kao pri pojedinačnom unosu stola, a greška nosi polje i stol na koji se odnosi.
        private static void ValidateTables(List<TableItemRequest> tables, ValidationContext<TableLayoutRequest> context)
        {
            var sentIds = new HashSet<int>();
            for (var index = 0; index < tables.Count; index++)
            {
                var table = tables[index];
                var path = $"{nameof(TableLayoutRequest.Tables)}[{index}]";
                if (table == null)
                {
                    context.AddFailure(path, $"Stol na poziciji {index + 1}: podaci stola su obavezni.");
                    continue;
                }

                var label = TableLabel(table.Name, index);
                void Fail(string field, string message) => context.AddFailure($"{path}.{field}", $"{label}: {message}");

                if (string.IsNullOrWhiteSpace(table.Name))
                    Fail(nameof(TableItemRequest.Name), TableRules.NameRequired);
                else if (table.Name.Length > TableRules.NameMaxLength)
                    Fail(nameof(TableItemRequest.Name), TableRules.NameTooLong);

                if (table.NumberOfGuests < TableRules.MinGuests || table.NumberOfGuests > TableRules.MaxGuests)
                    Fail(nameof(TableItemRequest.NumberOfGuests), TableRules.GuestsOutOfRange);

                if (table.XCoordinate < 0)
                    Fail(nameof(TableItemRequest.XCoordinate), TableRules.XCoordinateNegative);

                if (table.YCoordinate < 0)
                    Fail(nameof(TableItemRequest.YCoordinate), TableRules.YCoordinateNegative);

                if (table.Id != 0 && !sentIds.Add(table.Id))
                    Fail(nameof(TableItemRequest.Id), "Tlocrt sadrži isti stol više puta. Osvježite tlocrt i pokušajte ponovo.");
            }
        }

        private static string TableLabel(string? name, int index)
        {
            if (string.IsNullOrWhiteSpace(name))
                return $"Stol na poziciji {index + 1}";

            var shownName = name.Length > TableRules.NameMaxLength ? name[..TableRules.NameMaxLength] + "..." : name;
            return $"Stol \"{shownName}\"";
        }
    }
}
