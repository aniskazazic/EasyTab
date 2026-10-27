using EasyTab.Model.Exceptions;
using FluentValidation;

namespace EasyTab.Services.Validators;

public static class UserValidationExtensions
{
    public static async Task ValidateForUserAsync<T>(this IValidator<T> validator, T request)
    {
        var result = await validator.ValidateAsync(request);
        if (!result.IsValid)
            throw new UserException(string.Join(" ", result.Errors.Select(error => error.ErrorMessage).Distinct()));
    }
}
