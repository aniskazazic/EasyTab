using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class WorkerUpdateValidator : AbstractValidator<WorkerUpdateRequest>
    {
        public WorkerUpdateValidator()
        {
            RuleFor(x => x.Username)
                .MaximumLength(50).WithMessage("Korisničko ime ne može imati više od 50 karaktera.")
                .Matches(@"^[a-zA-Z0-9_]+$").WithMessage("Korisničko ime smije sadržavati samo slova, brojeve i donju crtu.")
                .When(x => !string.IsNullOrEmpty(x.Username));

            RuleFor(x => x.FirstName)
                 .MaximumLength(50).WithMessage("Ime ne može imati više od 50 karaktera.")
                 .When(x => !string.IsNullOrEmpty(x.FirstName));

            RuleFor(x => x.LastName)
                .MaximumLength(50).WithMessage("Prezime ne može imati više od 50 karaktera.")
                .When(x => !string.IsNullOrEmpty(x.LastName));

            RuleFor(x => x.Email)
                .EmailAddress().WithMessage("Email adresa nije ispravnog formata.")
                .MaximumLength(100).WithMessage("Email ne može imati više od 100 karaktera.")
                .When(x => !string.IsNullOrEmpty(x.Email));

            RuleFor(x => x.Password)
                .MinimumLength(6).WithMessage("Lozinka mora imati najmanje 6 karaktera.")
                .When(x => !string.IsNullOrEmpty(x.Password));

            RuleFor(x => x.PhoneNumber)
                .MaximumLength(20).WithMessage("Broj telefona ne može imati više od 20 karaktera.")
                .Matches(@"^\+?[0-9\s\-]+$").WithMessage("Broj telefona nije ispravnog formata.")
                .When(x => !string.IsNullOrEmpty(x.PhoneNumber));

            RuleFor(x => x.BirthDate)
                .LessThan(DateTime.UtcNow).WithMessage("Datum rođenja ne može biti u budućnosti.")
                .GreaterThan(new DateTime(1900, 1, 1)).WithMessage("Datum rođenja nije validan.")
                .When(x => x.BirthDate.HasValue);
        }
    }
}
