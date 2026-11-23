using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class ZoneLayoutValidator : AbstractValidator<ZoneLayoutRequest>
    {
        public ZoneLayoutValidator()
        {
            RuleFor(x => x.LocaleId)
                .GreaterThan(0).WithMessage(ZoneRules.LocaleRequired);

            // Zahtjev bez liste zona odbija već model binding (polje nije nullable), pa ovdje lista uvijek postoji.
            RuleFor(x => x.Zones)
                .Custom(ValidateZones);
        }

        // Isto pravilo naziva kao pri pojedinačnom unosu zone, a greška nosi polje i poziciju zone.
        private static void ValidateZones(List<ZoneItemRequest> zones, ValidationContext<ZoneLayoutRequest> context)
        {
            for (var index = 0; index < zones.Count; index++)
            {
                var zone = zones[index];
                var path = $"{nameof(ZoneLayoutRequest.Zones)}[{index}]";
                var label = $"Zona na poziciji {index + 1}";
                if (zone == null)
                {
                    context.AddFailure(path, $"{label}: podaci zone su obavezni.");
                    continue;
                }

                var namePath = $"{path}.{nameof(ZoneItemRequest.Name)}";
                if (string.IsNullOrWhiteSpace(zone.Name))
                    context.AddFailure(namePath, $"{label}: {ZoneRules.NameRequired}");
                else if (zone.Name.Length > ZoneRules.NameMaxLength)
                    context.AddFailure(namePath, $"{label}: {ZoneRules.NameTooLong}");
            }
        }
    }
}
