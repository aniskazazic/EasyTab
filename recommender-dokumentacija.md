# EasyTab — dokumentacija sistema preporuke

## 1. Opis sistema

EasyTab je aplikacija za pregled ugostiteljskih objekata i rezervaciju stolova. Sistem preporuke korisnicima predlaže lokale koji odgovaraju njihovim interesima i prethodnim aktivnostima u aplikaciji.

Preporuke se prikazuju na početnom ekranu mobilne aplikacije, u sekciji **„Preporučeno za vas“**. Cilj je olakšati pronalazak relevantnih lokala na osnovu korisnikovih dosadašnjih izbora, uz kratko objašnjenje svake preporuke. Sistem vraća najviše **tri lokala** po zahtjevu.

## 2. Korišteni pristup

Za personalizovane preporuke koristi se **Content-based Filtering**, odnosno preporučivanje na osnovu karakteristika lokala i profila interesovanja korisnika. Sličnost između korisničkog profila i lokala računa se pomoću **kosinusne sličnosti (cosine similarity)**.

Korisnički profil formira se iz završenih rezervacija, aktivnih favorita i recenzija. Sistem analizira kategorije, gradove, prosječne ocjene i popularnost lokala s kojima je korisnik imao te interakcije, a zatim pronalazi druge lokale sa sličnim karakteristikama.

Primjer: ako korisnik često posjećuje restorane u Mostaru i dodaje ih u favorite, kategorija „Restoran“ i grad „Mostar“ dobijaju veći doprinos njegovom profilu. Drugi restorani i lokali u Mostaru mogu zbog toga biti bolje rangirani, uz istovremeno uvažavanje njihove ocjene i popularnosti.

Kada nema dovoljno personalizovanih rezultata, koristi se rezervni pristup zasnovan na **prosječnoj ocjeni i popularnosti lokala**.

## 3. Interakcije korisnika

Za formiranje korisničkog profila koriste se sljedeći signali:

| Interakcija | Doprinos težini lokala | Pravilo |
| --- | --- | --- |
| Završena rezervacija | `1.0` po rezervaciji | Najviše pet završenih rezervacija po korisniku i lokalu ulazi u ovu težinu |
| Aktivan favorit | `1.5` | Računa se jednom po lokalu |
| Neobrisana korisnička recenzija | `(ocjena - 3) / 2 × 2` | Niske ocjene daju negativan, a visoke pozitivan doprinos |

Ocjena recenzije prevodi se u sljedeću težinu:

| Ocjena | Težina recenzije |
| --- | --- |
| 1 | −2 |
| 2 | −1 |
| 3 | 0 |
| 4 | +1 |
| 5 | +2 |

Za korisnika `u` i lokal `l` ukupna težina računa se kao:

```text
w(u, l) = min(broj završenih rezervacija, 5) × 1.0
          + aktivan favorit × 1.5
          + zbir težina korisnikovih neobrisanih recenzija
```

Vrijednost „aktivan favorit“ je `1` ako postoji aktivan zapis, a inače `0`.

Primjer: korisnik ima dvije završene rezervacije u lokalu, dodao ga je u favorite i ocijenio ocjenom 5. Ukupna težina tog lokala iznosi:

```text
2 × 1.0 + 1 × 1.5 + (5 - 3) / 2 × 2 = 5.5
```

Negativna recenzija smanjuje ukupnu težinu, ali doprinos rezervacija i favorita može zadržati njen zbir pozitivnim. Interakcije s obrisanim lokalima ne ulaze u profil.

Završene rezervacije grade lični profil korisnika. Potvrđene i završene rezervacije svih korisnika koriste se za popularnost lokala. Rezervacije na čekanju i otkazane rezervacije ne doprinose ovim izračunima.

## 4. Karakteristike lokala

Svaki neobrisani lokal predstavlja se vektorom koji sadrži četiri grupe karakteristika:

| Karakteristika | Način predstavljanja |
| --- | --- |
| Kategorija | One-hot komponenta: `1` za kategoriju kojoj lokal pripada, `0` za ostale |
| Grad | One-hot komponenta: `1` za grad u kojem se lokal nalazi, `0` za ostale |
| Prosječna ocjena | Prosjek svih neobrisanih recenzija lokala podijeljen sa `5` |
| Popularnost | Broj potvrđenih i završenih rezervacija lokala podijeljen najvećim takvim brojem među neobrisanim lokalima |

Kategorije i gradovi imaju odvojene komponente vektora. Ocjena i popularnost normalizuju se na raspon od `0` do `1`:

```text
R(l) = prosječna ocjena lokala / 5
N(l) = broj potvrđenih i završenih rezervacija lokala
M = najveći N(l) među neobrisanim lokalima
P(l) = N(l) / M

v(l) = [one-hot kategorija, one-hot grad, R(l), P(l)]
```

Ako lokal nema recenzija, komponenta ocjene je `0`. Ako nema rezervacija, komponenta popularnosti je `0`. Kada nijedan neobrisani lokal nema potvrđenih ili završenih rezervacija, popularnost svih lokala postavlja se na `0`.

Ograničenje od pet rezervacija odnosi se samo na ličnu težinu korisnika za određeni lokal. Globalna popularnost broji sve potvrđene i završene rezervacije tog lokala.

## 5. Formiranje profila i izračunavanje sličnosti

Korisnički profil dobija se sabiranjem vektora lokala s kojima je korisnik imao interakcije, pomnoženih njihovim ukupnim težinama:

```text
profil(u) = zbir [w(u, l) × v(l)]
```

Na taj način profil obuhvata korisnikove preferencije kategorija i gradova te karakteristike ocjene i popularnosti lokala koje bira. Negativni doprinosi recenzija zadržavaju se u izračunu.

Za svaki kandidat računa se kosinusna sličnost između njegovog vektora i korisničkog profila:

```text
similarity(u, l) = dot(profil(u), v(l))
                   / (norm(profil(u)) × norm(v(l)))
```

`dot` je skalarni proizvod vektora, a `norm` njihova dužina. Veća pozitivna vrijednost označava veću podudarnost lokala s korisničkim profilom.

Budući da lokal ima jednu kategoriju i jedan grad, norma njegovog vektora iznosi:

```text
norm(v(l)) = sqrt(2 + R(l)² + P(l)²)
```

Kosinusna sličnost računa se kada korisnički profil ima nenultu normu. U personalizovani dio preporuka ulaze samo kandidati s pozitivnom sličnošću.

## 6. Generisanje preporuka

Za prijavljenog korisnika sistem:

1. Učitava neobrisane lokale i priprema njihove karakteristike.
2. Prikuplja korisnikove završene rezervacije, aktivne favorite i neobrisane recenzije.
3. Formira korisnički profil koristeći težine tih interakcija.
4. Isključuje iz kandidata lokale za koje korisnik ima završenu rezervaciju, aktivan favorit ili neobrisanu recenziju.
5. Za preostale kandidate izračunava kosinusnu sličnost s profilom.
6. Zadržava pozitivne rezultate i sortira ih opadajuće po sličnosti.
7. Po potrebi dopunjava listu rezervnim rezultatima i vraća najviše tri lokala.

Kada kandidati imaju isti rezultat, prednost imaju viša ocjena, zatim veća popularnost, a na kraju manji identifikator radi stabilnog redoslijeda. Identifikator se koristi interno.

Lokal s neobrisanom neutralnom recenzijom, ocjene 3, također se isključuje iz kandidata iako je doprinos te recenzije težini jednak nuli. Potvrđena rezervacija ili rezervacija na čekanju sama po sebi ne isključuje lokal.

Preporuka označava relevantnost lokala. Dostupnost stolova i termina provjerava se zasebno u toku rezervacije.

## 7. Cold-start i dopuna rezultata

Ako korisnik nema prethodnih interakcija, njegov profil je nulti i sistem koristi rezervno rangiranje. Nulti profil može nastati i kada se doprinosi interakcija međusobno ponište.

Isti rezervni mehanizam dopunjava listu kada nema dovoljno kandidata s pozitivnom kosinusnom sličnošću. Za preostale kandidate računa se:

```text
ColdScore(l) = 0.5 × R(l) + 0.5 × P(l)
```

Ocjena i popularnost imaju jednak udio u ovom rezultatu. Kandidati se sortiraju opadajuće po `ColdScore`, uz iste dodatne kriterije: ocjena, popularnost i identifikator.

Personalizovane preporuke ostaju na početku liste, a rezervne se dodaju iza njih, bez ponovnog zajedničkog sortiranja. Lokal koji nije imao pozitivnu sličnost s profilom može se pojaviti u dopuni na osnovu ocjene i popularnosti.

Za sve rezervne preporuke prikazuje se objašnjenje:

> Najpopularniji i najbolje ocijenjeni lokali

Ako postoji manje od tri odgovarajuća kandidata, vraća se manji broj rezultata. Ako nema kandidata, odgovor je prazna lista.

## 8. Objašnjenje i prikaz preporuka

Svaka personalizovana preporuka sadrži objašnjenje formirano iz doprinosa četiri karakteristike:

- podudaranje kategorije s dosadašnjim izborima korisnika;
- podudaranje grada s dosadašnjim izborima korisnika;
- podudaranje prosječne ocjene lokala s profilom;
- podudaranje popularnosti lokala s profilom.

Servis bira najviše **dva najveća pozitivna doprinosa** i spaja ih u rečenicu koja počinje sa „Preporučeno jer“.

Primjer objašnjenja:

> Preporučeno jer prosječna ocjena lokala odgovara vašem profilu i grad „Mostar“ odgovara vašim dosadašnjim izborima.

Kartica u sekciji „Preporučeno za vas“ prikazuje logo, naziv lokala, kategoriju, grad, prosječnu ocjenu i objašnjenje. Otvaranjem kartice korisnik prelazi na postojeći ekran detalja lokala.

Sekcija je dostupna prijavljenom Korisniku koji nema ulogu Radnik. Ako lista preporuka ostane prazna ili dohvaćanje ne uspije, sekcija se skriva, a ostatak početnog ekrana ostaje dostupan.

Preporuke se osvježavaju pri učitavanju i osvježavanju početnog ekrana te nakon uspješnih promjena favorita i recenzija. Pri narednom API zahtjevu profil se računa iz trenutnog stanja baze.

## 9. Tehnička implementacija

Sistem je implementiran u servisnom sloju backend aplikacije:

- [RecommendationService.cs](EasyTab/EasyTab.Services/Services/RecommendationService.cs) — priprema osobina, formiranje profila, rangiranje, dopuna i objašnjenja.
- [RecommendationConstants.cs](EasyTab/EasyTab.Services/Services/RecommendationConstants.cs) — težine interakcija i ograničenja broja rezultata.
- [LocaleController.cs](EasyTab/EasyTab.API/Controllers/LocaleController.cs) — API endpoint za dohvaćanje preporuka.
- [RecommendedLocaleResponse.cs](EasyTab/EasyTab.Model/Models/RecommendedLocaleResponse.cs) — struktura odgovora.

Servis koristi **Entity Framework Core** za upite nad SQL Server bazom i asinhrono izvršavanje. Identitet korisnika preuzima iz `ICurrentUserService`, na osnovu JWT-a. Profil i preporuke računaju se pri zahtjevu, bez zasebnog treniranja i pohranjivanja korisničkog profila.

### API endpoint

| Endpoint | Pristup | Odgovor |
| --- | --- | --- |
| `GET /Locale/recommended` | Autentifikovan korisnik s ulogom `Korisnik` | Lista od 0 do 3 `RecommendedLocaleResponse` objekta |

Endpoint koristi fiksno ograničenje od tri rezultata. Korisnički identitet određuje se iz prijave.

Svaki rezultat sadrži:

| Polje | Opis |
| --- | --- |
| `Id` | Identifikator potreban za otvaranje detalja lokala |
| `Name` | Naziv lokala |
| `CategoryName` | Naziv kategorije |
| `CityName` | Naziv grada |
| `AverageRating` | Prosječna ocjena na skali 0–5; vrijednost 0 kada nema recenzija |
| `Logo` | Logo lokala, ako postoji |
| `Explanation` | Objašnjenje preporuke |
| `Score` | Kosinusna sličnost za personalizovani rezultat ili `ColdScore` za rezervni rezultat |

Mobilna aplikacija čuva redoslijed koji je odredio server. `Score` se ne prikazuje korisniku i ne koristi se za zajedničko sortiranje personalizovanih i rezervnih rezultata, jer predstavlja dva različita načina rangiranja.

Za dohvaćanje i stanje preporuka zadužen je [RecommendationProvider](EasyTab/UI/easytab_mobile/lib/providers/recommendation_provider.dart), a kartice prikazuje [RecommendedLocalesSection](EasyTab/UI/easytab_mobile/lib/widgets/recommended_locales_section.dart).
