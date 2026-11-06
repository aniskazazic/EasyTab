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

SignalR omogućava osvježavanje obavijesti u aplikacijama bez ručnog ponovnog učitavanja.

## RabbitMQ i email obavijesti

EasyTab koristi tok **API → RabbitMQ → EasyTab.Subscriber → SMTP → email korisnika**. API objavljuje događaj, a Subscriber preuzima poruku i šalje odgovarajući email:

- Nakon registracije — poruka dobrodošlice.
- Nakon kreiranja, potvrde ili otkazivanja rezervacije — obavijest korisniku o rezervaciji.
- Pri resetu lozinke — kod za oporavak koji vrijedi 15 minuta.

**Pri registraciji koristite stvarnu email adresu kojoj imate pristup.** Na tu adresu stižu obavijesti o rezervacijama i kod za reset lozinke. **Za reset lozinke unesite istu adresu koja je povezana s vašim EasyTab računom.**

Za dostavu emailova moraju biti pokrenuti RabbitMQ i Subscriber, uz ispravne SMTP postavke `Email__*` u `EasyTab/.env`. SMTP postavke određuju pošiljaoca, dok se adresa primaoca uzima iz EasyTab korisničkog računa.

## Struktura projekta

```text
EasyTab/                              # Korijen repozitorija
├── README.md
├── recommender-dokumentacija.md
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

## Preduslovi

- Instaliran i pokrenut Docker Desktop
- Android emulator (za testiranje mobilne aplikacije)
- Windows OS (za desktop aplikaciju)
- Alat za raspakivanje arhiva koji podržava .zip datoteke zaštićene lozinkom

## Pokretanje backenda

### 1. Priprema konfiguracije

Konfiguracijski fajl **`.env`** mora biti pored `docker-compose.yml`.

Za pokretanje s pripremljenom konfiguracijom raspakovati `.env` iz arhive `.env-tajne.zip` u taj repozitorij. Lozinka arhive dostavlja se odvojeno uz predaju rada.

Za vlastitu konfiguraciju kopirati javni šablon:

```sh
cd EasyTab
cp .env.example .env
```

### 2. Pokretanje servisa

Iz repozitorija `EasyTab`, u kojem su `docker-compose.yml` i `.env`:

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

### Zaustavljanje i reset baze

Uobičajeno zaustavljanje, uz čuvanje podataka:

```sh
docker compose down
```

Seed je namijenjen prvom pokretanju na praznoj bazi. Postojeći `DbSeeder` preskače seed ako već postoji barem jedan zapis u bilo kojoj od tabela Users, Roles, Countries ili Categories. Ponovnim pokretanjem kontejnera podaci se zadržavaju.

Za ponovno početno punjenje baze:

```sh
docker compose down -v
docker compose up --build
```

**`down -v` briše SQL volumen i sve podatke u njemu.**

## Pokretanje desktop aplikacije — Windows

1. Raspakujte arhivu izdanja (build) sa GitHub-a Release
2. Otvoriti Release folder
3. Pokrenuti `easytab_desktop.exe`

## Pokretanje mobilne aplikacije — Android

1. Pokrenite Android emulator
2. Iz GitHub Release, pronađite datoteku app-release.apk
3. Deinstalirajte sve prethodne verzije aplikacije
4. Prenesite i instalirajte .apk datoteku na emulator 
5. Pokrenite EasyTab na uređaju

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

**Za prijem email obavijesti i koda za reset lozinke registrujte novi EasyTab račun sa svojom stvarnom email adresom.** Adrese seedovanih računa nisu zamjena za inbox kojem imate pristup.

## Plaćanje — PayPal sandbox

Plaćanje se izvršava kroz PayPal sandbox. Backend čuva iznose u KM, a naplatu šalje u EUR prema kursu `PayPal__BamToEurRate` iz `.env`.

**Za email obavijesti koristi se stvarna adresa EasyTab korisničkog računa. PayPal sandbox adrese navedene ispod koriste se za prijavu u sandbox plaćanje.**

| Podatak PayPal sandbox kupca | Vrijednost |
| --- | --- |
| Email | `sb-7v71d53715721@personal.example.com` |
| Lozinka | `m<^$EY7?` |

ili

| Podatak PayPal sandbox kupca | Vrijednost |
| --- | --- |
| Email | `sb-3kwug53478888@personal.example.com` |
| Lozinka | `51_wDDmj` |


Nakon uspješne naplate kreira se rezervacija koja čeka potvrdu lokala. Otkazivanje plaćene rezervacije prema dozvoljenim pravilima uključuje povrat sredstava kroz PayPal.

## Sistem preporuke

Detaljan opis algoritma nalazi se u [dokumentaciji sistema preporuke](recommender-dokumentacija.md).

## 🚢 GitHub Release

Build fajlovi za pregled rada objavljuju se kroz [GitHub Releases](https://github.com/aniskazazic/EasyTab/releases) i ne dodaju se u Git historiju repozitorija.

Za svaku predaju priprema se jedan Release s jednom ZIP arhivom, npr. `fit-build-2026-11-08.zip`, sljedeće strukture:

```text
fit-build-2026-11-08.zip
├── easytab_mobile/
│   └── app-release.apk
└── easytab_desktop/
    └── Release/
        ├── easytab_desktop.exe
        ├── data/
        ├── flutter_windows.dll
        └── ostale potrebne DLL datoteke
```

> `.env` se ne uključuje u Release ZIP. Konfiguraciju s tajnama predati odvojeno kao šifrovanu arhivu `EasyTab/.env-tajne.zip`, u istom folderu gdje se koristi `.env`. Lozinku arhive dostaviti putem DLWMS-a zajedno s linkom na konkretan GitHub Release.


