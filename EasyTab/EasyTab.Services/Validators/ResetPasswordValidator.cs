using EasyTab.Model.Requests;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class ResetPasswordValidator : AbstractValidator<ResetPasswordRequest>
    {
        public ResetPasswordValidator()
        {
            RuleFor(x => x.Email)
                .NotEmpty().WithMessage("Email je obavezan.")
                .EmailAddress().WithMessage("Email adresa nije ispravnog formata.")
                .MaximumLength(100).WithMessage("Email ne može imati više od 100 karaktera.");

            RuleFor(x => x.Code)
                .NotEmpty().WithMessage("Kod je obavezan.")
                .Length(6).WithMessage("Kod mora imati 6 cifara.")
                .Matches(@"^\d{6}$").WithMessage("Kod se mora sastojati od 6 cifara.");

            RuleFor(x => x.NewPassword)
                .NotEmpty().WithMessage("Lozinka je obavezna.")
                .MinimumLength(6).WithMessage("Lozinka mora imati najmanje 6 karaktera.");

            RuleFor(x => x.ConfirmNewPassword)
                .NotEmpty().WithMessage("Potvrda lozinke je obavezna.")
                .Equal(x => x.NewPassword).WithMessage("Lozinka i potvrda lozinke moraju biti iste.");
        }
    }
}
