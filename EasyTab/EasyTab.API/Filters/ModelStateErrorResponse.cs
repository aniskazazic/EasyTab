using EasyTab.Model.Serialization;
using Microsoft.AspNetCore.Mvc;

namespace EasyTab.API.Filters;

public static class ModelStateErrorResponse
{
    public static IActionResult Create(ActionContext context)
    {
        var errors = context.ModelState
            .Where(entry => entry.Value is { Errors.Count: > 0 })
            .ToDictionary(entry => entry.Key, entry => new[] { MessageFor(entry.Key) });

        return new BadRequestObjectResult(new
        {
            message = errors.Values.SelectMany(messages => messages).FirstOrDefault()
                ?? "Provjerite unesene podatke.",
            errors
        });
    }

    private static string MessageFor(string key) => key.Split('.').Last().ToLowerInvariant() switch
    {
        "lengthofreservation" => ReservationDurationMessages.InvalidValue,
        "birthdate" => "Datum rođenja nije ispravan. Unesite datum u formatu GGGG-MM-DD.",
        "username" => "Korisničko ime je obavezno i smije sadržavati samo slova, brojeve i donju crtu, najviše 50 karaktera.",
        "name" => "Naziv je obavezan i mora biti ispravnog formata.",
        "firstname" => "Ime je obavezno i mora biti ispravnog formata.",
        "lastname" => "Prezime je obavezno i mora biti ispravnog formata.",
        "address" => "Adresa je obavezna i mora biti ispravnog formata.",
        "phonenumber" => "Broj telefona nije ispravnog formata.",
        "email" => "Email adresa je obavezna i mora biti ispravnog formata.",
        "password" => "Lozinka je obavezna i mora biti ispravnog formata.",
        "passwordconfirmation" => "Potvrda lozinke je obavezna i mora biti ispravnog formata.",
        "countryid" => "Odaberite ispravnu državu.",
        "cityid" => "Odaberite ispravan grad.",
        "categoryid" => "Odaberite ispravnu kategoriju.",
        "reservationprice" => "Cijena rezervacije mora biti broj od 1 do 100 KM, s najviše dvije decimale.",
        "startofworkinghours" or "endofworkinghours" => "Radno vrijeme je obavezno i mora biti u formatu HH:mm.",
        _ => "Podaci nisu ispravnog formata ili nedostaje obavezna vrijednost. Provjerite unos."
    };
}
