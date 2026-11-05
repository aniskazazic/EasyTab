using EasyTab.Model.Requests;
using FluentValidation;
using EasyTab.Services.Database;
using Microsoft.EntityFrameworkCore;

namespace EasyTab.Services.Validators
{
    public class RoleInsertValidator : AbstractValidator<RoleInsertRequest>
    {
        public RoleInsertValidator(_220030Context context)
        {
            RuleFor(x => x.Name)
                .Cascade(CascadeMode.Stop)
                .NotEmpty().WithMessage("Naziv uloge je obavezan.")
                .MaximumLength(50).WithMessage("Naziv uloge može imati najviše 50 znakova.")
                .MustAsync(async (name, cancellationToken) =>
                {
                    var normalizedName = name.Trim().ToUpperInvariant();
                    return !await context.Roles.AnyAsync(
                        role => role.Name.Trim().ToUpper() == normalizedName, cancellationToken);
                }).WithMessage("Uloga s ovim nazivom već postoji.");

            RuleFor(x => x.Description)
                .MaximumLength(100).WithMessage("Opis uloge može imati najviše 100 znakova.");
        }
    }
}
