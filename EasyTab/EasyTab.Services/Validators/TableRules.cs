namespace EasyTab.Services.Validators
{
    // Granice i poruke za stol na jednom mjestu: koriste ih pojedinačni unos, izmjena i spremanje tlocrta.
    internal static class TableRules
    {
        public const int NameMaxLength = 50;
        public const int MinGuests = 1;
        public const int MaxGuests = 8;

        public const string NameRequired = "Naziv stola je obavezan.";
        public static readonly string NameTooLong = $"Naziv stola ne može imati više od {NameMaxLength} karaktera.";
        public static readonly string GuestsOutOfRange = $"Broj gostiju mora biti između {MinGuests} i {MaxGuests}.";
        public const string LocaleRequired = "Lokal je obavezan.";
        public const string XCoordinateNegative = "X koordinata mora biti pozitivna.";
        public const string YCoordinateNegative = "Y koordinata mora biti pozitivna.";
    }
}
