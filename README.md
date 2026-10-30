# EasyTab

Platforma za pregled ugostiteljskih objekata i rezervaciju stolova.

Seminarski rad iz predmeta **Razvoj softvera II**, Fakultet informacijskih tehnologija u Mostaru.

## O projektu

EasyTab povezuje goste, vlasnike i radnike ugostiteljskih objekata. Korisnici putem mobilne aplikacije pregledaju lokale, pronalaze slobodne termine, rezervišu stolove i plaćaju rezervacije kroz PayPal sandbox. Personalizovane preporuke olakšavaju izbor lokala prema prethodnim aktivnostima korisnika.

Desktop aplikacija omogućava administratoru upravljanje sistemom, a vlasnicima upravljanje svojim lokalima, rasporedom stolova, radnicima i rezervacijama. Radnici koriste mobilnu aplikaciju za pregled i otkazivanje rezervacija u lokalima u kojima rade.

## Uloge i funkcionalnosti

| Uloga | Aplikacija | Glavne odgovornosti |
| --- | --- | --- |
| Korisnik | Flutter mobile — Android | Pregled lokala, preporuke, favoriti, rezervacije, plaćanje, recenzije i profil |
| Radnik | Flutter mobile — Android | Pregled rezervacija dodijeljenih lokala, detalji i otkazivanje uz razlog |
| Vlasnik | Flutter desktop — Windows | Upravljanje vlastitim lokalima, stolovima, zonama, radnicima i rezervacijama |
| Administrator | Flutter desktop — Windows | Upravljanje korisnicima, lokalima, rezervacijama, recenzijama i referentnim podacima |

### Mobilna aplikacija — korisnik

- Registracija, prijava, odjava i reset lozinke putem email koda.
- Pretraga i filtriranje lokala, pregled detalja, galerije i recenzija.
- Personalizovane preporuke u sekciji „Preporučeno za vas“.
- Dodavanje i uklanjanje lokala iz favorita.
- Odabir lokala, stola, datuma, termina i broja gostiju.
- Plaćanje rezervacije putem PayPal sandboxa.
- Pregled vlastitih rezervacija i otkazivanje prema pravilima rezervacije, uz povrat naplaćenog iznosa kroz PayPal kada je primjenjivo.
- Dodavanje i uređivanje recenzija nakon završene rezervacije.
- Uređivanje profila i prikaz obavijesti putem SignalR-a.

### Desktop aplikacija

- Administratorski i vlasnički dashboard.
- Upravljanje korisnicima, lokalima, državama, gradovima i kategorijama, prema ulozi.
- Upravljanje rezervacijama i praćenje njihovih stanja.
- Upravljanje recenzijama.
- Raspored stolova i zona unutar lokala.
- Upravljanje radnicima i postavkama vlastitih lokala.
- Generisanje PDF izvještaja za administratora i vlasnika.

## Arhitektura i tehnologije

| Komponenta | Tehnologija / namjena |
| --- | --- |
| `EasyTab.API` | ASP.NET Core 8 REST API, kontroleri, JWT autentifikacija i SignalR hub |
| `EasyTab.Services` | Poslovna logika, Entity Framework Core, migracije, seed, preporuke i PayPal integracija |
| `EasyTab.Model` | Modeli zahtjeva, odgovora i poruka |
| `EasyTab.Common.Services` | Zajednički servisi, uključujući obradu lozinki |
| `EasyTab.Subscriber` | .NET worker koji obrađuje RabbitMQ poruke i šalje SMTP emailove |
| `easytab_desktop` | Flutter aplikacija za Windows |
| `easytab_mobile` | Flutter aplikacija za Android |
| SQL Server 2022 | Baza podataka |
| RabbitMQ | Asinhrona komunikacija između API-ja i Subscribera |
| Docker Compose | Pokretanje API-ja, SQL Servera, RabbitMQ-a i Subscribera |
| PayPal sandbox | Plaćanje i povrat sredstava |

API obrađuje zahtjeve klijenata, a poslovna logika i pristup bazi nalaze se u servisnom sloju. Korisnički pristup zaštićen je JWT-om i provjerama uloga i vlasništva nad podacima.

RabbitMQ prenosi događaje registracije, kreiranja, potvrde i otkazivanja rezervacija te zahtjeve za reset lozinke. Subscriber obrađuje te poruke i šalje odgovarajuće emailove. SignalR omogućava osvježavanje obavijesti u aplikacijama bez ručnog ponovnog učitavanja.

## Struktura projekta

```text
EasyTab/                              # Korijen repozitorija
├── README.md
├── recommender.md
└── EasyTab/
    ├── EasyTab.sln
    ├── docker-compose.yml
    ├── Dockerfile
    ├── .env.example
    ├── EasyTab.API/
    ├── EasyTab.Services/
    ├── EasyTab.Model/
    ├── EasyTab.Common.Services/
    ├── EasyTab.Subscriber/
    └── UI/
        ├── easytab_desktop/
        └── easytab_mobile/
```

Komande u narednim odjeljcima polaze od **korijena repozitorija**, gdje se nalazi ovaj README. Svaki odjeljak za pokretanje započeti iz tog direktorija, u zasebnom terminalu.

## Preduvjeti

- Docker Desktop, pokrenut u režimu Linux kontejnera.
- Docker Engine 25+ i Docker Compose 2.20.2+ za korišteni `start_interval` u healthcheckovima.
- Flutter SDK s Dart verzijom kompatibilnom s `^3.11.1`, za pokretanje klijenata iz izvornog koda.
- Windows i Visual Studio s komponentom **Desktop development with C++**, za Windows Flutter build.
- Android SDK i Android emulator ili fizički Android uređaj, za mobilnu aplikaciju.
- Alat koji podržava raspakivanje ZIP arhiva zaštićenih lozinkom.

Za lokalni razvoj backenda izvan Dockera potreban je i .NET SDK 8. Pri Docker pokretanju .NET SDK i baza nalaze se u kontejnerima.

Ispravnost Flutter razvojnih alata može se provjeriti komandom:

```sh
flutter doctor
```

## Pokretanje backenda

### 1. Priprema konfiguracije

Konfiguracijski fajl mora biti na putanji **`EasyTab/.env`**, pored `docker-compose.yml`.

Za pokretanje s pripremljenom konfiguracijom raspakovati `.env` iz arhive `.env-tajne.zip` u taj direktorij. Lozinka arhive dostavlja se odvojeno uz predaju rada.

Za vlastitu konfiguraciju kopirati javni šablon:

```sh
cd EasyTab
cp .env.example .env
```

Popuniti SQL Server i RabbitMQ pristupne podatke, JWT postavke, CORS adrese, SMTP i PayPal sandbox postavke. `.env.example` ne sadrži stvarne tajne; popunjeni `.env` ne dodaje se u repozitorij.

Compose koristi `SA_PASSWORD` za SQL Server vezu API-ja, a `RABBITMQ_DEFAULT_USER` i `RABBITMQ_DEFAULT_PASS` za pristup brokeru. `ConnectionStrings__EasyTabConnection` i `RabbitMQ__Host` iz `.env` koriste se pri lokalnom pokretanju izvan Compose mreže; Compose postavlja interne adrese svojih servisa.

Za SMTP su dostupne postavke `Email__Host`, `Email__Port`, `Email__Username`, `Email__Password`, `Email__FromName`, `Email__FromAddress` i `Email__SecureSocketOptions`. Ako je FromAddress prazan, pošiljalac je Email__Username. Podržani režimi su `StartTls`, `SslOnConnect`, `Auto` i `None`, s defaultom `StartTls`. Port RabbitMQ veze postavlja se kroz `RabbitMQ__Port`, s defaultom `5672`.

### 2. Pokretanje servisa

Iz direktorija `EasyTab`, u kojem su Compose i `.env`:

```sh
docker compose up --build
```

Compose podiže SQL Server, RabbitMQ, API i Subscriber. API pri pokretanju automatski primjenjuje EF Core migracije i priprema početne podatke. Sačekati završetak migracija i seeda prije prijave kroz klijente.

### 3. Servisi i portovi

| Servis | Adresa na računaru |
| --- | --- |
| Backend API | `http://localhost:5241` |
| Swagger | `http://localhost:5241/swagger` |
| SQL Server | `localhost,1432` — unutar kontejnera port `1433` |
| RabbitMQ AMQP | `localhost:5672` |
| RabbitMQ management | `http://localhost:15672` |

Pristupni podaci RabbitMQ management konzole odgovaraju vrijednostima `RABBITMQ_DEFAULT_USER` i `RABBITMQ_DEFAULT_PASS` iz `.env`.

Swagger je dostupan kada je `ASPNETCORE_ENVIRONMENT=Development`, što je default u Compose konfiguraciji. U `Production` okruženju Swagger je isključen, dok se migracije i provjera seeda i dalje izvršavaju.

### Zaustavljanje i reset baze

Uobičajeno zaustavljanje, uz očuvanje podataka:

```sh
docker compose down
```

Seed je namijenjen prvom pokretanju na praznoj bazi. Postojeći `DbSeeder` preskače seed ako već postoji korisnik `desktop`. Ponovnim pokretanjem kontejnera podaci se zadržavaju.

Za ponovno početno punjenje baze:

```sh
docker compose down -v
docker compose up --build
```

**`down -v` briše SQL volumen i sve podatke u njemu.**

## Pokretanje desktop aplikacije — Windows

Iz korijena repozitorija:

```sh
cd EasyTab/UI/easytab_desktop
flutter pub get
flutter run -d windows
```

Default API adresa je `http://localhost:5241`. Ista adresa može se zadati eksplicitno:

```sh
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5241
```

Za drugi backend promijeniti vrijednost `API_BASE_URL` i ponovo pokrenuti aplikaciju. Desktop aplikaciji pristupaju administrator i vlasnik.

## Pokretanje mobilne aplikacije — Android

Pokrenuti emulator ili povezati Android uređaj, pa iz korijena repozitorija izvršiti:

```sh
cd EasyTab/UI/easytab_mobile
flutter pub get
flutter devices
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://10.0.2.2:5241
```

`<android-device-id>` zamijeniti identifikatorom iz komande `flutter devices`. Bez dart-define parametra mobile također koristi default `http://10.0.2.2:5241`.

`10.0.2.2` je adresa računara domaćina iz Android emulatora. Na fizičkom uređaju koristiti IP adresu računara u istoj lokalnoj mreži, na primjer:

```sh
flutter run -d <android-device-id> --dart-define=API_BASE_URL=http://192.168.1.100:5241
```

Adresu u primjeru zamijeniti stvarnom adresom računara i omogućiti pristup portu `5241`. Mobilnoj aplikaciji pristupaju korisnik i radnik.

## Testni računi

Računi su definisani u [DbSeeder.cs](EasyTab/EasyTab.Services/SeedData/DbSeeder.cs). Na svježe seedovanoj bazi svi navedeni računi koriste lozinku **`test`**.

| Korisničko ime | Lozinka | Uloga | Aplikacija |
| --- | --- | --- | --- |
| `desktop` | `test` | Administrator | Desktop |
| `mobile` | `test` | Korisnik | Mobile |
| `admin` | `test` | Administrator | Desktop |
| `vlasnik` | `test` | Vlasnik | Desktop |
| `vlasnik2` | `test` | Vlasnik | Desktop |
| `radnik` | `test` | Radnik | Mobile |
| `korisnik` | `test` | Korisnik | Mobile |
| `amina` | `test` | Korisnik | Mobile |

Računi `mobile`, `korisnik` i `amina` imaju seedovane interakcije koje omogućavaju demonstraciju različitih personalizovanih preporuka.

## Plaćanje — PayPal sandbox

Plaćanje se izvršava kroz PayPal sandbox. Backend čuva iznose u KM, a naplatu šalje u EUR prema kursu `PayPal__BamToEurRate` iz `.env`.

Potrebno je popuniti `PayPal__ClientId`, `PayPal__Secret` i ostale `PayPal__*` postavke prema [`.env.example`](EasyTab/.env.example). Aplikacijski račun i PayPal sandbox račun kupca koriste se u različitim koracima: u EasyTab se prijavljuje testnim računom iz prethodne tabele, a u PayPal prikazu sandbox kupcem.

| Podatak PayPal sandbox kupca | Vrijednost |
| --- | --- |
| Email | `<POPUNITI>` |
| Lozinka | `<POPUNITI>` |

Nakon uspješne naplate kreira se rezervacija koja čeka potvrdu lokala. Otkazivanje plaćene rezervacije prema dozvoljenim pravilima uključuje povrat sredstava kroz PayPal.

Za povratak iz PayPal prikaza koristiti putanje `/paypal/return` i `/paypal/cancel`, kao u `.env.example`, jer ih mobile WebView presreće pri odobrenju ili prekidu plaćanja.

## Sistem preporuke

EasyTab koristi **Content-based Filtering** s kosinusnom sličnošću između profila korisnika i karakteristika lokala. Profil se gradi iz završenih rezervacija, aktivnih favorita i recenzija, a lokal se opisuje kategorijom, gradom, ocjenom i popularnošću.

Za nove korisnike i dopunu rezultata koristi se rangiranje prema ocjeni i popularnosti. Na početnom ekranu prikazuju se najviše tri preporuke s objašnjenjima.

Detaljan opis algoritma, težina i API-ja nalazi se u [dokumentaciji sistema preporuke](recommender-dokumentacija.md).

## Provjera rada i česte poteškoće

Sve Docker komande izvršavati iz unutrašnjeg direktorija `EasyTab`:

```sh
docker compose ps
docker compose logs --tail 50 easytab-api easytab-subscriber
```

- Ako API još nije dostupan, provjeriti logove migracija i seeda te stanje SQL Servera i RabbitMQ-a.
- Ako klijent ne može pristupiti API-ju, provjeriti da je backend pokrenut i da `API_BASE_URL` odgovara Windowsu, emulatoru ili fizičkom uređaju.
- Ako Swagger nije dostupan, provjeriti `ASPNETCORE_ENVIRONMENT`; Swagger je uključen samo u Developmentu.
- Ako emailovi ne stižu, provjeriti SMTP postavke i Subscriber logove. Kod SMTP servisa koji koriste lozinku za aplikaciju postaviti tu lozinku u `.env`.
- Za novi seed koristiti reset volumena samo kada je namjera brisanje postojećih lokalnih podataka.
