using EasyTab.Common.Services.CryptoService;
using EasyTab.Services.Database;
using EasyTab.Services.ReservationStateMachine;
using Microsoft.EntityFrameworkCore;
using System.Reflection;

namespace EasyTab.Services.SeedData
{
    public class DbSeeder
    {
        private readonly _220030Context _context;
        private readonly ICryptoService _cryptoService;

        public DbSeeder(_220030Context context, ICryptoService cryptoService)
        {
            _context = context;
            _cryptoService = cryptoService;
        }

        public async Task SeedAsync()
        {
            if (await _context.Users.AnyAsync(user => user.Username == "desktop"))
                return;

            await using var transaction = await _context.Database.BeginTransactionAsync();

            var roles = CreateRoles();
            _context.Roles.AddRange(roles);
            await _context.SaveChangesAsync();

            var countries = CreateCountries();
            _context.Countries.AddRange(countries);
            await _context.SaveChangesAsync();

            var cities = CreateCities(countries);
            _context.Cities.AddRange(cities);
            await _context.SaveChangesAsync();

            var categories = CreateCategories();
            _context.Categories.AddRange(categories);
            await _context.SaveChangesAsync();

            var users = CreateUsers();
            _context.Users.AddRange(users.Values);
            await _context.SaveChangesAsync();

            _context.UserRoles.AddRange(CreateUserRoles(users, roles));
            await _context.SaveChangesAsync();

            var locales = CreateLocales(users, cities, categories);
            _context.Locales.AddRange(locales);
            await _context.SaveChangesAsync();

            AddProfilePictures(users);
            var localeImages = CreateLocaleImages(locales);
            _context.LocaleImages.AddRange(localeImages);

            var zones = CreateZones(locales);
            var tables = CreateTables(locales);
            _context.Zones.AddRange(zones);
            _context.Tables.AddRange(tables);
            await _context.SaveChangesAsync();

            var workers = CreateWorkers(users, locales);
            _context.Workers.AddRange(workers);
            await _context.SaveChangesAsync();

            var localeOwnersById = locales.ToDictionary(
                locale => locale.Id,
                locale => users.Values.First(user => user.Id == locale.OwnerId));
            var reservations = CreateReservations(users, tables, localeOwnersById);
            _context.Reservations.AddRange(reservations);
            await _context.SaveChangesAsync();

            var reviews = CreateReviews(users, locales);
            _context.Reviews.AddRange(reviews);
            await _context.SaveChangesAsync();

            _context.Reactions.AddRange(CreateReactions(users, reviews));
            _context.Favourites.AddRange(CreateFavourites(users, locales));
            _context.Notifications.AddRange(CreateNotifications(users));
            await _context.SaveChangesAsync();

            await transaction.CommitAsync();
        }

        private static List<Role> CreateRoles()
        {
            return new List<Role>
            {
                new() { Name = "Admin", Description = "Administrator sistema", IsDeleted = false },
                new() { Name = "Vlasnik", Description = "Vlasnik lokala", IsDeleted = false },
                new() { Name = "Radnik", Description = "Radnik u lokalu", IsDeleted = false },
                new() { Name = "Korisnik", Description = "Korisnik aplikacije", IsDeleted = false }
            };
        }

        private static readonly string[] RegularUserUsernames =
        {
            "mobile", "korisnik", "amina", "nikola", "lejla", "tarik", "elena", "faris",
            "maja", "hamza", "ivana", "selma", "marko", "sara", "vedad"
        };

        private static List<Country> CreateCountries()
        {
            return new List<Country>
            {
                new() { Name = "Bosna i Hercegovina" },
                new() { Name = "Hrvatska" },
                new() { Name = "Srbija" },
                new() { Name = "Crna Gora" },
                new() { Name = "Slovenija" },
                new() { Name = "Austrija" },
                new() { Name = "Njemačka" },
                new() { Name = "Italija" },
                new() { Name = "Mađarska" },
                new() { Name = "Turska" }
            };
        }

        private static List<City> CreateCities(IReadOnlyList<Country> countries)
        {
            var definitions = new[]
            {
                (Name: "Mostar", CountryIndex: 0), (Name: "Sarajevo", CountryIndex: 0),
                (Name: "Banja Luka", CountryIndex: 0), (Name: "Tuzla", CountryIndex: 0),
                (Name: "Zenica", CountryIndex: 0), (Name: "Zagreb", CountryIndex: 1),
                (Name: "Split", CountryIndex: 1), (Name: "Beograd", CountryIndex: 2),
                (Name: "Novi Sad", CountryIndex: 2), (Name: "Podgorica", CountryIndex: 3),
                (Name: "Ljubljana", CountryIndex: 4), (Name: "Maribor", CountryIndex: 4),
                (Name: "Beč", CountryIndex: 5), (Name: "Graz", CountryIndex: 5),
                (Name: "Berlin", CountryIndex: 6), (Name: "Minhen", CountryIndex: 6),
                (Name: "Rim", CountryIndex: 7), (Name: "Milano", CountryIndex: 7),
                (Name: "Budimpešta", CountryIndex: 8), (Name: "Istanbul", CountryIndex: 9)
            };

            return definitions.Select(definition => new City
            {
                Name = definition.Name,
                CountryId = countries[definition.CountryIndex].Id
            }).ToList();
        }

        private static List<Category> CreateCategories()
        {
            return new List<Category>
            {
                new() { Name = "Restoran", Description = "Restorani sa kompletnom ponudom hrane" },
                new() { Name = "Kafić", Description = "Kafići i mjesta za kafu" },
                new() { Name = "Fast food", Description = "Brza hrana" },
                new() { Name = "Pizzeria", Description = "Pizzerije" },
                new() { Name = "Lounge bar", Description = "Lounge barovi i večernji izlazak" }
            };
        }

        private Dictionary<string, User> CreateUsers()
        {
            var definitions = new List<(string Username, string FirstName, string LastName, string Email)>
            {
                (Username: "desktop", FirstName: "Desktop", LastName: "Test", Email: "desktop@easytab.test"),
                (Username: "mobile", FirstName: "Mobile", LastName: "Test", Email: "mobile@easytab.test"),
                (Username: "admin", FirstName: "Sistem", LastName: "Administrator", Email: "admin@easytab.test"),
                (Username: "vlasnik", FirstName: "Marko", LastName: "Vlasnik", Email: "vlasnik@easytab.test"),
                (Username: "vlasnik2", FirstName: "Selma", LastName: "Hodžić", Email: "vlasnik2@easytab.test"),
                (Username: "radnik", FirstName: "Ana", LastName: "Radnik", Email: "radnik@easytab.test"),
                (Username: "radnik2", FirstName: "Ivan", LastName: "Kovač", Email: "radnik2@easytab.test"),
                (Username: "radnik3", FirstName: "Lejla", LastName: "Hadžić", Email: "radnik3@easytab.test"),
                (Username: "radnik4", FirstName: "Emir", LastName: "Marić", Email: "radnik4@easytab.test"),
                (Username: "radnik5", FirstName: "Adnan", LastName: "Delić", Email: "radnik5@easytab.test"),
                (Username: "radnik6", FirstName: "Ena", LastName: "Kurtović", Email: "radnik6@easytab.test"),
                (Username: "radnik7", FirstName: "Dino", LastName: "Bećirović", Email: "radnik7@easytab.test"),
                (Username: "radnik8", FirstName: "Amra", LastName: "Omerović", Email: "radnik8@easytab.test"),
                (Username: "korisnik", FirstName: "Test", LastName: "Korisnik", Email: "korisnik@easytab.test"),
                (Username: "amina", FirstName: "Amina", LastName: "Kovačević", Email: "amina@easytab.test"),
                (Username: "nikola", FirstName: "Nikola", LastName: "Jovanović", Email: "nikola@easytab.test"),
                (Username: "lejla", FirstName: "Lejla", LastName: "Memić", Email: "lejla@easytab.test"),
                (Username: "tarik", FirstName: "Tarik", LastName: "Šabić", Email: "tarik@easytab.test"),
                (Username: "elena", FirstName: "Elena", LastName: "Marković", Email: "elena@easytab.test"),
                (Username: "faris", FirstName: "Faris", LastName: "Čolić", Email: "faris@easytab.test"),
                (Username: "maja", FirstName: "Maja", LastName: "Radić", Email: "maja@easytab.test"),
                (Username: "hamza", FirstName: "Hamza", LastName: "Alić", Email: "hamza@easytab.test"),
                (Username: "ivana", FirstName: "Ivana", LastName: "Perić", Email: "ivana@easytab.test"),
                (Username: "selma", FirstName: "Selma", LastName: "Begić", Email: "selma@easytab.test"),
                (Username: "marko", FirstName: "Marko", LastName: "Tomić", Email: "marko@easytab.test"),
                (Username: "sara", FirstName: "Sara", LastName: "Hasanović", Email: "sara@easytab.test"),
                (Username: "vedad", FirstName: "Vedad", LastName: "Husić", Email: "vedad@easytab.test")
            };

            return definitions.ToDictionary(
                definition => definition.Username,
                definition =>
                {
                    var salt = _cryptoService.GenerateSalt();
                    return new User
                    {
                        Username = definition.Username,
                        FirstName = definition.FirstName,
                        LastName = definition.LastName,
                        Email = definition.Email,
                        PasswordSalt = salt,
                        PasswordHash = _cryptoService.GenerateHash("test", salt),
                        PhoneNumber = "+38761100000",
                        BirthDate = new DateTime(1990, 1, 1),
                        IsDeleted = false
                    };
                });
        }

        private static List<UserRole> CreateUserRoles(IReadOnlyDictionary<string, User> users, IReadOnlyList<Role> roles)
        {
            var rolesByName = roles.ToDictionary(role => role.Name);
            var assignments = new Dictionary<string, string>
            {
                ["desktop"] = "Admin",
                ["mobile"] = "Korisnik",
                ["admin"] = "Admin",
                ["vlasnik"] = "Vlasnik",
                ["vlasnik2"] = "Vlasnik",
                ["radnik"] = "Radnik",
                ["radnik2"] = "Radnik",
                ["radnik3"] = "Radnik",
                ["radnik4"] = "Radnik",
                ["radnik5"] = "Radnik",
                ["radnik6"] = "Radnik",
                ["radnik7"] = "Radnik",
                ["radnik8"] = "Radnik",
                ["korisnik"] = "Korisnik"
            };

            foreach (var username in users.Keys.Where(username => !assignments.ContainsKey(username)))
                assignments[username] = "Korisnik";

            return assignments.Select(assignment => new UserRole
            {
                UserId = users[assignment.Key].Id,
                RoleId = rolesByName[assignment.Value].Id,
                IsDeleted = false
            }).ToList();
        }

        private static List<Locale> CreateLocales(IReadOnlyDictionary<string, User> users, IReadOnlyList<City> cities, IReadOnlyList<Category> categories)
        {
            var definitions = new[]
            {
                (Name: "Tima-Irma", Address: "Onešćukova 8, Mostar", Phone: "+387 61 891 189", CityIndex: 0, CategoryIndex: 0, Image: "tima-irma.jpg"),
                (Name: "Hindin Han", Address: "Jusovina 6, Mostar", Phone: "+387 61 178 220", CityIndex: 0, CategoryIndex: 0, Image: "hindin-han.jpg"),
                (Name: "Restaurant Divan", Address: "Jusovina 6, Mostar", Phone: "+387 61 333 444", CityIndex: 0, CategoryIndex: 0, Image: "restaurant-divan.jpg"),
                (Name: "Megi", Address: "Kneza Višeslava 2, Mostar", Phone: "+387 36 551 555", CityIndex: 0, CategoryIndex: 3, Image: "megu.jpg"),
                (Name: "Mala Kuhinja", Address: "Maršala Tita 54, Sarajevo", Phone: "+387 61 555 777", CityIndex: 1, CategoryIndex: 1, Image: "urban-cafe.jpg"),
                (Name: "Vatra", Address: "Ferhadija 4, Sarajevo", Phone: "+387 33 222 333", CityIndex: 1, CategoryIndex: 4, Image: "lounge-bar.jpg"),
                (Name: "Ćevabdžinica Hari", Address: "Kujundžiluk 6, Mostar", Phone: "+387 61 404 505", CityIndex: 0, CategoryIndex: 2, Image: null),
                (Name: "Sadrvan", Address: "Jusovina 11, Mostar", Phone: "+387 61 606 707", CityIndex: 0, CategoryIndex: 0, Image: null),
                (Name: "Konoba Taurus", Address: "Maršala Tita 22, Mostar", Phone: "+387 36 808 909", CityIndex: 0, CategoryIndex: 0, Image: null),
                (Name: "Bistro Zdravo", Address: "Zmaja od Bosne 12, Sarajevo", Phone: "+387 61 111 212", CityIndex: 1, CategoryIndex: 1, Image: null),
                (Name: "Pizzeria Dino", Address: "Ferhadija 18, Sarajevo", Phone: "+387 33 313 414", CityIndex: 1, CategoryIndex: 3, Image: null),
                (Name: "Baščaršija Grill", Address: "Sarači 9, Sarajevo", Phone: "+387 61 515 616", CityIndex: 1, CategoryIndex: 2, Image: null),
                (Name: "Kazandžiluk Coffee", Address: "Kazandžiluk 3, Sarajevo", Phone: "+387 61 717 818", CityIndex: 1, CategoryIndex: 1, Image: null),
                (Name: "Una Riverside", Address: "Kralja Petra I 15, Banja Luka", Phone: "+387 65 919 202", CityIndex: 2, CategoryIndex: 4, Image: null),
                (Name: "Tuzla House", Address: "Trg slobode 4, Tuzla", Phone: "+387 61 323 424", CityIndex: 3, CategoryIndex: 0, Image: null),
                (Name: "Zenica Pizza", Address: "Maršala Tita 31, Zenica", Phone: "+387 61 525 626", CityIndex: 4, CategoryIndex: 3, Image: null),
                (Name: "Zagreb Table", Address: "Tkalčićeva 18, Zagreb", Phone: "+385 91 727 828", CityIndex: 5, CategoryIndex: 0, Image: null),
                (Name: "Split Sunset Bar", Address: "Marmontova 7, Split", Phone: "+385 91 929 303", CityIndex: 6, CategoryIndex: 4, Image: null),
                (Name: "Novi Sad Bistro", Address: "Zmaj Jovina 16, Novi Sad", Phone: "+381 64 131 424", CityIndex: 8, CategoryIndex: 1, Image: null)
            };

            return definitions.Select((definition, index) => new Locale
            {
                Name = definition.Name,
                Address = definition.Address,
                PhoneNumber = definition.Phone,
                StartOfWorkingHours = new TimeOnly(8, 0),
                EndOfWorkingHours = new TimeOnly(23, 0),
                LengthOfReservation = 2,
                Logo = definition.Image == null ? null : ReadImage(definition.Image),
                CityId = cities[definition.CityIndex].Id,
                CategoryId = categories[definition.CategoryIndex].Id,
                OwnerId = index < 9 ? users["vlasnik"].Id : users["vlasnik2"].Id,
                IsDeleted = false
            }).ToList();
        }

        private void AddProfilePictures(IReadOnlyDictionary<string, User> users)
        {
            users["desktop"].ProfilePicture = ReadImage("profile-desktop.jpg");
            users["mobile"].ProfilePicture = ReadImage("profile-mobile.jpg");
            users["vlasnik"].ProfilePicture = ReadImage("profile-owner.jpg");
        }

        private List<LocaleImage> CreateLocaleImages(IReadOnlyList<Locale> locales)
        {
            var images = new List<LocaleImage>();
            var imageNames = new[] { "tima-irma.jpg", "hindin-han.jpg", "restaurant-divan.jpg", "megu.jpg", "urban-cafe.jpg", "lounge-bar.jpg" };

            foreach (var (locale, imageName, galleryName) in locales.Zip(imageNames).Zip(imageNames.Skip(1).Append(imageNames[0]), (front, gallery) => (front.First, front.Second, gallery)))
            {
                images.Add(new LocaleImage
                {
                    FileName = $"{imageName}-front.jpg",
                    ContentType = "image/jpeg",
                    Base64Content = ReadImage(galleryName),
                    CreatedAt = DateTime.UtcNow,
                    LocaleId = locale.Id
                });
                images.Add(new LocaleImage
                {
                    FileName = $"{imageName}-gallery.jpg",
                    ContentType = "image/jpeg",
                    Base64Content = ReadImage(imageName),
                    CreatedAt = DateTime.UtcNow,
                    LocaleId = locale.Id
                });
            }

            return images;
        }

        private static List<Zone> CreateZones(IReadOnlyList<Locale> locales)
        {
            return locales.SelectMany((locale, localeIndex) => new[]
            {
                new Zone { Name = "Sala", LocaleId = locale.Id, Xcoordinate = 10, Ycoordinate = 10, Width = 280, Height = 180 },
                new Zone { Name = "Terasa", LocaleId = locale.Id, Xcoordinate = 320, Ycoordinate = 10, Width = 280, Height = 180 }
            }).ToList();
        }

        private static List<Table> CreateTables(IReadOnlyList<Locale> locales)
        {
            return locales.SelectMany(locale => Enumerable.Range(1, 6).Select(tableNumber => new Table
            {
                Name = $"Stol {tableNumber}",
                LocaleId = locale.Id,
                Xcoordinate = 30 + (tableNumber - 1) % 3 * 90,
                Ycoordinate = 40 + (tableNumber - 1) / 3 * 80,
                NumberOfGuests = tableNumber % 2 == 0 ? 4 : 2
            })).ToList();
        }

        private static List<Worker> CreateWorkers(IReadOnlyDictionary<string, User> users, IReadOnlyList<Locale> locales)
        {
            var workerNames = new[] { "radnik", "radnik2", "radnik3", "radnik4", "radnik5", "radnik6", "radnik7", "radnik8" };
            return locales.Take(workerNames.Length).Select((locale, index) => new Worker
            {
                UserId = users[workerNames[index]].Id,
                LocaleId = locale.Id,
                HireDate = DateTime.UtcNow.AddMonths(-6 - index),
                IsDeleted = false
            }).ToList();
        }

        private static List<Reservation> CreateReservations(
            IReadOnlyDictionary<string, User> users,
            IReadOnlyList<Table> tables,
            IReadOnlyDictionary<int, User> localeOwnersById)
        {
            var reservationUsers = RegularUserUsernames.Select(username => users[username]).ToList();
            var reservations = new List<Reservation>();
            var states = new[]
            {
                PendingReservationState.StateName,
                ConfirmedReservationState.StateName,
                CancelledReservationState.StateName,
                CompletedReservationState.StateName
            };

            for (var stateIndex = 0; stateIndex < states.Length; stateIndex++)
            {
                for (var itemIndex = 0; itemIndex < 30; itemIndex++)
                {
                    var state = states[stateIndex];
                    var reservationDate = stateIndex switch
                    {
                        0 => DateTime.UtcNow.Date.AddDays(5 + itemIndex),
                        1 => DateTime.UtcNow.Date.AddDays(12 + itemIndex),
                        2 => DateTime.UtcNow.Date.AddDays(-(10 + itemIndex)),
                        _ => DateTime.UtcNow.Date.AddDays(-(25 + itemIndex))
                    };
                    var user = reservationUsers[(stateIndex * 30 + itemIndex) % reservationUsers.Count];
                    var table = tables[(stateIndex * 30 + itemIndex) % tables.Count];
                    var approver = localeOwnersById[table.LocaleId];
                    var start = new TimeOnly(12 + itemIndex % 6, 0);
                    var reservation = new Reservation
                    {
                        UserId = user.Id,
                        TableId = table.Id,
                        ReservationDate = reservationDate,
                        StartTime = start,
                        EndTime = start.AddHours(2),
                        CreatedAt = reservationDate.AddDays(-2),
                        ReservationState = state
                    };

                    if (stateIndex == 1 || stateIndex == 3)
                    {
                        reservation.ApprovedById = approver.Id;
                        reservation.ApprovedAt = reservation.CreatedAt.AddHours(2);
                    }

                    if (stateIndex == 2)
                    {
                        reservation.CancelledById = approver.Id;
                        reservation.CancelledAt = reservation.CreatedAt.AddHours(3);
                        reservation.CancellationReason = "Testna rezervacija otkazana radi seed podataka.";
                    }

                    reservations.Add(reservation);
                }
            }

            return reservations;
        }

        private static List<Review> CreateReviews(IReadOnlyDictionary<string, User> users, IReadOnlyList<Locale> locales)
        {
            var authors = RegularUserUsernames.Select(username => users[username]).ToList();
            var ratingsByLocale = new[]
            {
                new[] { 5, 5, 5, 5, 4, 5 },
                new[] { 5, 5, 4, 5, 4, 5 },
                new[] { 5, 4, 5, 4, 4, 5 },
                new[] { 4, 4, 5, 4, 3, 4 },
                new[] { 4, 3, 4, 4, 3, 4 },
                new[] { 4, 3, 3, 4, 3, 4 }
            };

            return Enumerable.Range(0, locales.Count * 6).Select(index => new Review
            {
                Description = new[]
                {
                    "Odlična usluga i vrlo ukusna hrana. Ambijent je posebno lijep.",
                    "Porcije su obilne, osoblje ljubazno, a čekanje kratko.",
                    "Prijatno mjesto za ručak sa porodicom. Sigurno ćemo se vratiti.",
                    "Hrana je svježa i lijepo servirana, posebno preporučujem domaće specijalitete.",
                    "Lijep ambijent u starom gradu i korektne cijene.",
                    "Kafa je odlična, a terasa je ugodna za duži razgovor."
                }[index % 6],
                Rating = index < ratingsByLocale.Length * 6
                    ? ratingsByLocale[index / 6][index % 6]
                    : 3 + index % 3,
                UserId = authors[index % authors.Count].Id,
                LocaleId = locales[index / 6].Id,
                DateAdded = DateTime.UtcNow.AddDays(-(index + 1)),
                IsDeleted = false
            }).ToList();
        }

        private static List<Reaction> CreateReactions(IReadOnlyDictionary<string, User> users, IReadOnlyList<Review> reviews)
        {
            var usersForReactions = RegularUserUsernames.Select(username => users[username]).ToList();
            return Enumerable.Range(0, 150).Select(index => new Reaction
            {
                ReviewId = reviews[index % reviews.Count].Id,
                UserId = usersForReactions[index % usersForReactions.Count].Id,
                IsLike = index % 3 != 0
            }).ToList();
        }

        private static List<Favourite> CreateFavourites(IReadOnlyDictionary<string, User> users, IReadOnlyList<Locale> locales)
        {
            var favouriteUsers = RegularUserUsernames.Select(username => users[username]).ToList();
            return Enumerable.Range(0, 50).Select(index => new Favourite
            {
                UserId = favouriteUsers[index % favouriteUsers.Count].Id,
                LocaleId = locales[index % locales.Count].Id,
                DateAdded = DateTime.UtcNow.AddDays(-index),
                IsActive = true
            }).ToList();
        }

        private static List<Notification> CreateNotifications(IReadOnlyDictionary<string, User> users)
        {
            var recipients = RegularUserUsernames
                .Select(username => users[username])
                .Concat(new[] { users["vlasnik"], users["vlasnik2"], users["radnik"] })
                .ToList();
            return Enumerable.Range(0, 50).Select(index => new Notification
            {
                UserId = recipients[index % recipients.Count].Id,
                Title = index % 2 == 0 ? "Dobro došli u EasyTab" : "Nova testna obavijest",
                Message = "Ova obavijest je dodana seed podacima za testiranje aplikacije.",
                IsRead = index % 3 == 0,
                CreatedAt = DateTime.UtcNow.AddDays(-index)
            }).ToList();
        }

        private static string ReadImage(string fileName)
        {
           var assembly = typeof(DbSeeder).GetTypeInfo().Assembly;
            var resourceName = assembly.GetManifestResourceNames()
                .First(name => name.EndsWith($".{fileName}", StringComparison.OrdinalIgnoreCase));

            using var stream = assembly.GetManifestResourceStream(resourceName)!;
            using var memoryStream = new MemoryStream();
            stream.CopyTo(memoryStream);
            return Convert.ToBase64String(memoryStream.ToArray());
        }
    }
}
