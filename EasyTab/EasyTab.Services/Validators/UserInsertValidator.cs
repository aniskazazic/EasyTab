using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class UserInsertValidator : AbstractValidator<UserInsertRequest>
    {
        public UserInsertValidator()
        {
            RuleFor(x => x.FirstName)
                .NotEmpty().WithMessage("Ime je obavezno.")
                .MaximumLength(50).WithMessage("Ime ne može imati više od 50 karaktera.");

            RuleFor(x => x.LastName)
                .NotEmpty().WithMessage("Prezime je obavezno.")
                .MaximumLength(50).WithMessage("Prezime ne može imati više od 50 karaktera.");

            RuleFor(x => x.Username)
                .NotEmpty().WithMessage("Korisničko ime je obavezno.")
                .MaximumLength(50).WithMessage("Korisničko ime ne može imati više od 50 karaktera.")
                .Matches(@"^[a-zA-Z0-9_]+$").WithMessage("Korisničko ime smije sadržavati samo slova, brojeve i donju crtu.");

            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email je obavezan.")
                .EmailAddress().WithMessage("Email adresa nije ispravnog formata.")
                .MaximumLength(100).WithMessage("Email ne može imati više od 100 karaktera.");

            RuleFor(x => x.Password)
                .NotEmpty().WithMessage("Lozinka je obavezna.")
                .MinimumLength(6).WithMessage("Lozinka mora imati najmanje 6 karaktera.");

            RuleFor(x => x.PasswordConfirmation)
                .NotEmpty().WithMessage("Potvrda lozinke je obavezna.")
                .Equal(x => x.Password).WithMessage("Lozinka i potvrda lozinke moraju biti iste.");

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
