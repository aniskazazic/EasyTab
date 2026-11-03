using EasyTab.Model.Requests;
using EasyTab.Services.Database;
using FluentValidation;
using Microsoft.EntityFrameworkCore;

namespace EasyTab.Services.Validators
{
    public class CategoryUpsertValidator : AbstractValidator<CategoryUpsertRequest>
    {
        public CategoryUpsertValidator(_220030Context context)
        {
            RuleFor(x => x.Name)
                .Cascade(CascadeMode.Stop)
                .NotEmpty().WithMessage("Naziv kategorije je obavezan.")
                .MaximumLength(100).WithMessage("Naziv kategorije ne može imati više od 100 karaktera.")
                .MustAsync(async (request, name, validationContext, cancellationToken) =>
                {
                    var id = validationContext.RootContextData.TryGetValue("Id", out var value)
                        ? (int)value : 0;
                    var names = await context.Categories.AsNoTracking()
                        .Where(category => category.Id != id)
                        .Select(category => category.Name)
                        .ToListAsync(cancellationToken);
                    var normalizedName = NormalizeName(name);
                    return names.All(existingName => NormalizeName(existingName) != normalizedName);
                }).WithMessage("Kategorija s istim nazivom već postoji.");
        
        RuleFor(x => x.Description)
                .NotEmpty().WithMessage("Opis je obavezan.")
                .MaximumLength(500).WithMessage("Opis ne može imati više od 500 karaktera.")
                .When(x => !string.IsNullOrEmpty(x.Description));
        }

        private static string NormalizeName(string name) =>
            string.Concat(name.Where(character => !char.IsWhiteSpace(character))).ToUpperInvariant();
    }
}
