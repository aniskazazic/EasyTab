using EasyTab.Model.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using System.Net;

namespace EasyTab.API.Filters
{
    public class ExceptionFilter : ExceptionFilterAttribute
    {
        private readonly ILogger<ExceptionFilter> _logger;

        public ExceptionFilter(ILogger<ExceptionFilter> logger)
        {
            _logger = logger;
        }

        public override void OnException(ExceptionContext context)
        {
            _logger.LogError(context.Exception, "Došlo je do greške.");

            // FluentValidation exceptions should be converted into model state errors
            if (context.Exception is FluentValidation.ValidationException fvEx)
            {
                foreach (var error in fvEx.Errors)
                {
                    // use property name (empty string for general errors) to key the message
                    context.ModelState.AddModelError(error.PropertyName ?? string.Empty, error.ErrorMessage);
                }

                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                _logger.LogWarning(context.Exception, "Validacija zahtjeva nije uspjela.");

            }
            else if (context.Exception is UserException ue)
            {
                context.ModelState.AddModelError("userError", ue.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                _logger.LogWarning("Korisničko pravilo: {Message}", ue.Message);
            }
            else if (context.Exception is InvalidRefreshTokenException invalidRefreshTokenException)
            {
                context.ModelState.AddModelError("refreshTokenError", invalidRefreshTokenException.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                _logger.LogWarning("Nevažeći token za obnovu: {Message}", invalidRefreshTokenException.Message);
            }
            else if (context.Exception is ForbiddenException forbiddenException)
            {
                context.ModelState.AddModelError("authorizationError", forbiddenException.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.Forbidden;
                _logger.LogWarning("Pristup zabranjen: {Message}", forbiddenException.Message);
            }
            else if (context.Exception is UnauthorizedAccessException unauthorizedAccessException)
            {
                context.ModelState.AddModelError("authorizationError", unauthorizedAccessException.Message);
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.Forbidden;
                _logger.LogWarning("Autorizacija nije uspjela: {Message}", unauthorizedAccessException.Message);
            }
            else if (context.Exception is NotFoundException || context.Exception is KeyNotFoundException)
            {
                context.ModelState.AddModelError("notFound", context.Exception is NotFoundException
                    ? context.Exception.Message
                    : "Traženi podatak nije pronađen.");
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.NotFound;
                _logger.LogWarning("Podatak nije pronađen: {Message}", context.Exception.Message);
            }
            else
            {
                context.ModelState.AddModelError("serverError", "Došlo je do greške na serveru. Pokušajte ponovo kasnije.");
                context.HttpContext.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                _logger.LogError(context.Exception, "Neobrađena greška.");
            }

            var list = context.ModelState
                .Where(c => c.Value is { Errors.Count: > 0 })
                .ToDictionary(
                    c => c.Key,
                    c => c.Value!.Errors.Select(z => z.ErrorMessage).ToList());

            // Single human-readable line for mobile/clients; "clientError" is used for ClientException.
            var allMessages = list.Values.SelectMany(v => v).Where(m => !string.IsNullOrWhiteSpace(m)).ToList();
            var message = allMessages.FirstOrDefault()
                ?? (context.Exception is UserException ? context.Exception.Message : null)
                ?? "Zahtjev nije moguće obraditi.";

            context.Result = new JsonResult(new
            {
                message,
                errors = list
            });


        }
    }
}
