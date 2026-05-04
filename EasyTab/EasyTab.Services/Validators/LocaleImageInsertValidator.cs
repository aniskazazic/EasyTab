using EasyTab.Model.Requests;
using FluentValidation;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace EasyTab.Services.Validators
{
    public class LocaleImageInsertValidator : AbstractValidator<LocaleImageInsertRequest>
    {
        public LocaleImageInsertValidator()
        {
            RuleFor(x => x.FileName)
                .NotEmpty().WithMessage("Naziv datoteke je obavezan.")
                .MaximumLength(100).WithMessage("Naziv datoteke ne može imati više od 100 karaktera.");

            RuleFor(x => x.ContentType)
                .NotEmpty().WithMessage("Tip sadržaja je obavezan.")
                .MaximumLength(100).WithMessage("Tip sadržaja ne može imati više od 100 karaktera.");

            RuleFor(x => x.Base64Content)
                .NotEmpty().WithMessage("Base64 sadržaj je obavezan.");

            RuleFor(x => x.LocaleId)
                .GreaterThan(0).WithMessage("Lokal je obavezan i mora biti veći od 0.");
        }
    }
}
