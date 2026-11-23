namespace EasyTab.Services.Validators
{
    // Granice i poruke za naziv zone na jednom mjestu: koriste ih pojedinačni unos, izmjena i spremanje tlocrta.
    internal static class ZoneRules
    {
        public const int NameMaxLength = 50;

        public const string NameRequired = "Naziv zone je obavezan.";
        public static readonly string NameTooLong = $"Naziv zone ne može imati više od {NameMaxLength} karaktera.";
        public const string LocaleRequired = "Lokal je obavezan.";
    }
}
