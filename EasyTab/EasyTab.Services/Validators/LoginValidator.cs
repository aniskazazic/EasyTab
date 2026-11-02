using EasyTab.Model.Access;
using FluentValidation;

namespace EasyTab.Services.Validators
{
    public class LoginValidator : AbstractValidator<UserLoginRequest>
    {
        public LoginValidator()
        {
            RuleFor(x => x.Username)
                .MaximumLength(50).WithMessage("Korisničko ime ne može imati više od 50 karaktera.");

            RuleFor(x => x.Password)
                .MaximumLength(100).WithMessage("Lozinka ne može imati više od 100 karaktera.");
        }
    }
}
