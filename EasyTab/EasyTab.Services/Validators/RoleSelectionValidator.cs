using EasyTab.Services.Database;
using FluentValidation;
using FluentValidation.Results;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace EasyTab.Services.Validators
{
    public static class RoleSelectionValidator
    {
        public const string PropertyName = "RoleIds";

        public static async Task<List<int>> EnsureActiveRolesAsync(_220030Context context, IEnumerable<int> roleIds)
        {
            var requestedIds = roleIds.Distinct().ToList();
            var roles = await context.Roles
                .Where(role => requestedIds.Contains(role.Id))
                .Select(role => new { role.Id, role.Name, role.IsDeleted })
                .ToListAsync();

            var deletedRoleNames = roles
                .Where(role => role.IsDeleted)
                .Select(role => $"'{role.Name}'")
                .ToList();
            var missingCount = requestedIds.Count - roles.Count;

            if (deletedRoleNames.Count == 0 && missingCount == 0)
                return requestedIds;

            var messages = new List<string>();
            if (deletedRoleNames.Count == 1)
                messages.Add($"Uloga {deletedRoleNames[0]} više nije dostupna.");
            else if (deletedRoleNames.Count > 1)
                messages.Add($"Uloge {string.Join(", ", deletedRoleNames)} više nisu dostupne.");
            if (missingCount > 0)
                messages.Add("Jedna ili više odabranih uloga više ne postoji.");
            messages.Add("Odaberite važeću ulogu i spremite ponovo.");

            throw new ValidationException(new[]
            {
                new ValidationFailure(PropertyName, string.Join(" ", messages))
            });
        }
    }
}
