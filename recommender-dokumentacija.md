# EasyTab — sistem preporuke lokala

Dokument opisuje implementaciju u [RecommendationService.cs](EasyTab/EasyTab.Services/Services/RecommendationService.cs),
[RecommendationConstants.cs](EasyTab/EasyTab.Services/Services/RecommendationConstants.cs) i
[RecommendedLocaleResponse.cs](EasyTab/EasyTab.Model/Models/RecommendedLocaleResponse.cs).

## Endpoint i izlaz

`GET /Locale/recommended` je dostupan samo ulozi `Korisnik`. Servis je scoped, a
korisnički identitet dolazi iz `ICurrentUserService`, bez parametra `userId`.
Vraća se JSON lista od 0 do 3 lokala, s poljima `Id`, `Name`, `CategoryName`,
`CityName`, `AverageRating`, `Logo`, `Explanation` i `Score` (JSON koristi camelCase).
Nova tabela, trajno spremanje profila i treniranje modela nisu potrebni: profil se
izračunava pri svakom zahtjevu iz trenutnog stanja baze.

## Ulazni podaci i njihovo upisivanje

| Podatak | Gdje se upisuje | Kako ulazi u preporuku |
| --- | --- | --- |
| Kategorija i grad lokala | Kreiranje/izmjena lokala, `LocaleService` | One-hot komponente vektora lokala i profila |
| Rezervacija: korisnik, stol i stanje | Mobilni checkout, `PaymentService` i reservation state machine; kasnije promjene stanja kroz rezervacije | Korisnikove završene rezervacije grade profil; potvrđene i završene rezervacije svih korisnika grade popularnost |
| Recenzija: ocjena, korisnik, lokal i `IsDeleted` | Dodavanje/izmjena kroz `Reviews` i `ReviewService`; brisanje postavlja soft-delete | Neobrisane ocjene grade prosječnu ocjenu; korisnikova ocjena dodatno određuje težinu interakcije |
| Favorit: korisnik, lokal i `IsActive` | `POST /Favourites/add` kreira ili aktivira zapis; `DELETE /Favourites/remove` postavlja `IsActive = false` | Aktivni favorit daje težinu jednom po lokalu |

U aplikacijskom toku recenzija zahtijeva završenu rezervaciju, a identitet autora
server određuje iz prijavljenog korisnika. Opis recenzije i reakcije na recenziju
ne učestvuju u preporuci. Ne koriste se historija pretraga, klikovi, cijena,
vrijeme rezervacije, slike ili status plaćanja kao signali.

Podaci o rezervacijama povezuju se s lokalom preko `Reservation.Table.LocaleId`.
Prepoznaju se vrijednosti `ConfirmedReservationState.StateName` (Potvrđena) i
`CompletedReservationState.StateName` (Završena). Stanja Na čekanju i Otkazana
ne grade ni korisnički profil ni popularnost.

Plaćanje nije uslov za čitanje završene rezervacije. Seedana završena rezervacija
bez uplate ima isti doprinos kao završena rezervacija s uplatom. Nova rezervacija
iz mobilnog checkouta sama po sebi još ne postaje korisnički signal: mora preći
u stanje Završena. Klijent nakon kreiranja ponovo dohvaća preporuke, ali promjena
liste tada nije zagarantovana.

## Vektor lokala

Za lokal `l` koristi se vektor:

```text
v(l) = [one-hot kategorija, one-hot grad, R(l), P(l)]
R(l) = prosječna ocjena svih neobrisanih recenzija lokala / 5
N(l) = broj potvrđenih + broj završenih rezervacija lokala, za sve korisnike
M    = najveći N među neobrisanim lokalima
P(l) = N(l) / M
```

Kategorija i grad su dva odvojena prostora komponenti. Svaki lokal ima jednu
kategoriju i jedan grad, pa je zbir kvadrata njegovih one-hot komponenti `2`.
Bez recenzija je `R = 0`; bez rezervacija je `P = 0`. Ako je `M = 0`, sve
komponente popularnosti su `0`, bez dijeljenja nulom. U odgovor se ocjena vraća
na skali 0–5, a ne u normaliziranom obliku.

## Konstante i težine

Vrijednosti su centralizovane u [RecommendationConstants.cs](EasyTab/EasyTab.Services/Services/RecommendationConstants.cs).

| Konstanta | Vrijednost | Namjena |
| --- | --- | --- |
| `ResultLimit` | 3 | Najveći broj preporuka |
| `CompletedReservationCap` | 5 | Najviše pet završenih rezervacija po korisniku i lokalu za težinu profila |
| `CompletedReservationWeight` | 1.0 | Težina jedne završene rezervacije |
| `FavouriteWeight` | 1.5 | Težina aktivnog favorita |
| `NeutralRating` | 3.0 | Ocjena s nultom težinom recenzije |
| `ReviewRatingRange` | 2.0 | Normalizacija odstupanja ocjene od 3 |
| `ReviewWeight` | 2.0 | Množilac težine recenzije |
| `MaximumRating` | 5.0 | Normalizacija prosječne ocjene |
| `ColdRatingWeight` | 0.5 | Ocjena u ColdScore |
| `ColdPopularityWeight` | 0.5 | Popularnost u ColdScore |
| `OneHotSquaredNorm` | 2.0 | Dvije jedinične one-hot komponente lokala |
| `ExplanationFeatureLimit` | 2 | Najviše dva razloga u personalizovanom objašnjenju |

## Profil korisnika

Interakcije se uzimaju samo za neobrisane lokale. Za korisnika `u` i lokal `l`:

```text
C(u,l) = broj korisnikovih završenih rezervacija u lokalu
F(u,l) = 1 ako postoji aktivni favorit, inače 0
Wrec(u,l) = suma [(ocjena - 3) / 2 * 2] njegovih neobrisanih recenzija lokala
w(u,l) = min(C(u,l), 5) * 1.0 + F(u,l) * 1.5 + Wrec(u,l)
p(u) = suma [w(u,l) * v(l)]
```

Težine pojedinačnih recenzija za ocjene 1–5 redom su `-2, -1, 0, +1, +2`.
Servis sabira sve neobrisane korisnikove recenzije ako takvi zapisi postoje;
postojeći tok dodavanja ne dopušta novu aktivnu recenziju za isti par korisnik/lokal.
Ponovljeni zapisi favorita ne povećavaju težinu jer se ID-evi lokala dedupliciraju.
Cap od pet ograničava samo doprinos završenih rezervacija korisničkoj težini,
ne ograničava ukupan broj rezervacija u popularnosti lokala.

Negativne težine i komponente profila se zadržavaju. Negativna recenzija smanjuje
zbirnu težinu lokala, ali zbog rezervacija ili favorita ta težina može ostati pozitivna.

## Kandidati i cosine sličnost

Osnovni filter je `Locale.IsDeleted == false`, isti kao podrazumijevani `GET /Locale`
za Korisnika bez opcionalnih filtera pretrage. Ne provjeravaju se trenutno radno
vrijeme, slobodni stolovi ili soft-delete vlasnika, kategorije i grada.

Iz kandidata se isključuje lokal s bilo kojom od sljedećih korisnikovih interakcija:

- najmanje jedna završena rezervacija;
- aktivni favorit;
- neobrisana recenzija, uključujući neutralnu ocjenu 3.

Isključivanje važi i kada zbirna težina interakcija iznosi nula. Potvrđene,
otkazane i rezervacije na čekanju ne isključuju lokal iz kandidata.

Za nenulti profil računa se:

```text
cosine(u,l) = dot(p(u), v(l)) / (norm(p(u)) * norm(v(l)))
norm(v(l)) = sqrt(2 + R(l)^2 + P(l)^2)
```

U brojnik ulaze komponenta kategorije, komponenta grada, proizvod komponente
ocjene profila s `R(l)` i proizvod komponente popularnosti profila s `P(l)`.
Sve četiri grupe osobina učestvuju i u odgovarajućim normama.

Personalizovani dio prihvata samo `cosine > 0`; kod filtrira pozitivan brojnik,
što je ekvivalentno jer su norme pozitivne. Poredak je cosine silazno, pa ocjena
silazno, popularnost silazno i ID uzlazno radi determinističkog razrješenja izjednačenja.
Uzima se najviše tri kandidata. ID se koristi interno i ne prikazuje se u UI-u.

## Cold start i dopuna

Korisnik bez interakcija ima nulti profil. Nulti profil može nastati i poništavanjem
težina ili samo neutralnim recenzijama. Za takav profil ne računa se cosine.

Ako personalizovanih rezultata nema ili ih je manje od tri, slobodna mjesta popunjavaju
se iz istog skupa kandidata, uz isključivanje već izabranih ID-eva:

```text
ColdScore(l) = 0.5 * R(l) + 0.5 * P(l)
```

Redoslijed dopune je ColdScore silazno, pa ocjena, popularnost i ID kao gore.
Kandidat čiji je cosine bio nula ili negativan može biti izabran kao dopuna prema
ColdScore. U dopuni tada nema tvrdnje da odgovara profilu korisnika.
Svaka dopuna dobija tačno objašnjenje:

> Najpopularniji i najbolje ocijenjeni lokali

Personalizovani dio ostaje prvi, a dopuna se dodaje iza njega. Rezultati se ne
sortiraju ponovo zajedno. Kada ukupno postoje samo dva, jedan ili nijedan kandidat,
odgovor ima upravo toliko elemenata.

## Objašnjenje personalizovane preporuke

Servis poredi četiri doprinosa brojniku cosine formule:

1. komponentu profila za kategoriju kandidata;
2. komponentu profila za grad kandidata;
3. komponentu ocjene profila pomnoženu s `R(l)`;
4. komponentu popularnosti profila pomnoženu s `P(l)`.

Zadržavaju se samo pozitivni doprinosi i uzimaju najveća dva. Pri jednakim
doprinosima ostaje prethodni redoslijed: kategorija, grad, ocjena, popularnost.
Zajednički nazivnik je pozitivan, pa bi dijeljenje svakog doprinosa tim nazivnikom
dalo isti redoslijed. Svaki pozitivan cosine ima najmanje jedan pozitivan doprinos.

Tekst počinje s „Preporučeno jer“, povezuje razloge sa „i“ i završava tačkom.
Razlozi se odnose na dosadašnje izbore za kategoriju/grad ili podudaranje ocjene/
popularnosti s profilom. Ne tvrdi se da je razlog često rezervisanje kada je
komponenta profila mogla nastati iz favorita ili recenzija.

## Značenje Score polja i mobilni prikaz

`Score` sadrži cosine za personalizovani rezultat, a ColdScore za dopunu. Ta dva
tipa skora nemaju isto značenje, pa se ne koriste za poređenje svih lokala u
kombinovanoj listi. Mobilni model čita polje, ali UI ga ne prikazuje i ne sortira po njemu.
Čuva se redoslijed primljene liste.

Samo Korisnik, koji nije Radnik, vidi sekciju „Preporučeno za vas“ iznad kategorija.
Kartica prikazuje logo preko postojećeg keša `ImageUtils` u
[utils.dart](EasyTab/UI/easytab_mobile/lib/providers/utils.dart), naziv, kategoriju,
grad, prosječnu ocjenu i cijelo objašnjenje. Klik prvo dohvaća puni lokal preko
`LocaleProvider.getById` i otvara postojeći ekran detalja; preporučeni DTO nema
sva polja potrebna tom ekranu.

Prazna lista i neuspješan poziv skrivaju sekciju. Provider zapisuje grešku u log,
bez dijaloga ili SnackBar poruke za neuspješno dohvaćanje preporuka; timeout je
10 sekundi. Neuspješno otvaranje punih detalja ima zasebnu poruku korisniku.
Nezavisno učitavanje kategorija/lokala i preporuka pokreće se kroz `Future.wait`.
Pozivi lokala po kategorijama također ostaju paralelni.

Osvježavanje se pokreće pri početnom učitavanju, ručnom povlačenju, povratku na
početni tab, povratku s ruta početne i povratku aplikacije iz pozadine. Uspješno
dodavanje/uklanjanje favorita i dodavanje/izmjena/brisanje recenzije odmah pokreću
novo dohvaćanje, kao i uspješno završen mobilni checkout koji je kreirao rezervaciju.
Zastarjeli odgovori se odbacuju ako je u međuvremenu pokrenut noviji zahtjev ili
se promijenio korisnički identitet. Preporuke se ne osvježavaju preko SignalR-a.

## Primjer iz stvarnih seed podataka

Izračun koristi neizmijenjene metode iz
[DbSeeder.cs](EasyTab/EasyTab.Services/SeedData/DbSeeder.cs): 27 lokala,
120 rezervacija, 162 recenzije i 50 aktivnih zapisa favorita. Maksimalna popularnost
je `M = 6`. Brojke u nastavku vrijede za čist seed, prije dodatnih interakcija.

Za korisnika `mobile` sljedeći lokali grade profil:

| Lokal | Završene rezervacije | Aktivni favorit | Korisnikova ocjena | Ukupna težina |
| --- | ---: | --- | ---: | ---: |
| Tima-Irma | 0 | da | 5 | 3.5 |
| Hindin Han | 1 | ne | — | 1 |
| Restaurant Divan | 0 | ne | 4 | 1 |
| Megi | 0 | da | — | 1.5 |
| Vatra | 0 | ne | 5 | 2 |
| Sadrvan | 0 | ne | 4 | 1 |
| Pizzeria Dino | 0 | ne | 5 | 2 |
| Kazandžiluk Coffee | 0 | ne | 4 | 1 |
| Zenica Pizza | 0 | da | 5 | 3.5 |
| Split Sunset Bar | 1 | ne | 4 | 2 |
| Novi Sad Bistro | 0 | da | — | 1.5 |
| Burger Point | 0 | ne | 5 | 2 |
| Taco Corner | 0 | ne | 4 | 1 |
| Skyline Lounge | 0 | ne | 4 | 1 |

Primjer težine Tima-Irma: `0 * 1 + 1 * 1.5 + (5 - 3) / 2 * 2 = 3.5`.
Nakon sabiranja vektora profil ima ove komponente:

| Grupa | Vrijednosti |
| --- | --- |
| Kategorije | Restoran 6.5; Pizzeria 7; Lounge bar 5; Kafić 2.5; Fast food 3 |
| Gradovi | Mostar 10; Sarajevo 6; Zenica 3.5; Split 2; Novi Sad 1.5; Banja Luka 1 |
| Ocjena | 21.483333333333 |
| Popularnost | 9.583333333333 |

Norma profila je `28.989202970915`. Kandidat Ćevabdžinica Hari je Fast food u
Mostaru, nema interakciju korisnika `mobile`, ima prosječnu ocjenu `29/6 = 4.833333333333`
i šest potvrđenih/završenih rezervacija. Njegove numeričke komponente su
`R = 29/30 = 0.966666666667` i `P = 6/6 = 1`.

```text
dot = 3 + 10 + 21.483333333333 * (29/30) + 9.583333333333 * 1
    = 43.350555555556
norm(v) = sqrt(2 + (29/30)^2 + 1) = 1.983543406242
cosine = 43.350555555556 / (28.989202970915 * 1.983543406242)
       = 0.753905104512
```

Najveća dva doprinosa su ocjena `20.767222222222` i grad `10`, pa je objašnjenje:

> Preporučeno jer prosječna ocjena lokala odgovara vašem profilu i grad „Mostar“ odgovara vašim dosadašnjim izborima.

Za korisnika bez historije isti lokal ima
`ColdScore = 0.5 * (29/30) + 0.5 * 1 = 0.983333333333` i cold start objašnjenje.
Razlika između `0.753905...` i `0.983333...` pokazuje zašto klijent ne smije
sortirati kombinovani odgovor po Score polju.

Na čistom seedu personalizovane liste su:

| Korisnik | Preporuke u redoslijedu servera |
| --- | --- |
| mobile | Ćevabdžinica Hari (0.753905); Konoba Taurus (0.724162); Bistro Zdravo (0.668595) |
| korisnik | Bistro Zdravo (0.794292); Konoba Taurus (0.685071); Megi (0.620155) |
| amina | Ćevabdžinica Hari (0.738708); Hindin Han (0.727734); Konoba Taurus (0.696191) |

Brojke su dokumentacijski prikaz; mobilni UI ih ne prikazuje. Izračun koristi
nerazlomljene vrijednosti, a ovdje prikazane decimale su zaokružene radi čitanja.

## Ograničenja

- Cosine ne reaguje na jednoliko pozitivno skaliranje cijelog profila: mijenja
  se njegova dužina, ali ne smjer. Zato svaki signal učestvuje u računu, ali njegova
  promjena ne mora na svakom skupu podataka promijeniti skor ili top listu.
- Negativna recenzija ne mora dati negativnu ukupnu težinu zbog ostalih interakcija.
- ColdScore nije statistička pouzdanost ocjene: prosjek jedne i prosjek mnogo
  recenzija nisu dodatno ponderisani brojem recenzija.
- Nema vremenskog opadanja težina; stare i nove interakcije koriste iste koeficijente.
- Profili koriste trenutne osobine lokala i trenutne globalne prosjeke/popularnost.
- Ako postoji manje od tri kandidata, vraća se manje od tri rezultata.
- Skrivanje preporuka nakon greške omogućava korištenje ostatka početne stranice,
  ali do uspješnog narednog osvježavanja preporuke nisu dostupne.

## Ručna provjera mobilnog klijenta

1. Registrovati novog Korisnika bez historije. Na početnoj provjeriti cold start
   tekst i 0–3 kartice iznad kategorija, bez Score vrijednosti.
2. Na čistom seedu prijaviti `mobile`, `korisnik` i `amina` (seed lozinka `test`)
   te provjeriti različite liste iz gornje tabele i očuvan redoslijed.
3. Kliknuti preporuku i provjeriti pune detalje lokala, uključujući podatke kojih nema
   u preporučenom DTO-u. Dodati lokal u favorite i vratiti se na početnu: lokal mora
   nestati iz preporuka, a ostali zadržati novi redoslijed servera. Uklanjanje favorita
   ponovo dopušta kandidaturu ako nema drugih interakcija.
4. Dodati/izmijeniti/obrisati dopuštenu recenziju, zatim se vratiti na početnu. Ponoviti
   nakon uspješnog kreiranja rezervacije. Provjeriti novo dohvaćanje; kreiranje
   rezervacije na čekanju ne mora odmah promijeniti skor ili listu.
5. Prijaviti `radnik`: sekcija nije prisutna i klijent ne zove endpoint preporuka.
6. Na izolovanoj razvojnoj bazi korisniku ukloniti sve dostupne kandidate kroz
   interakcije ili brisanje lokala, pa osvježiti početnu: prazan odgovor skriva
   sekciju. Sa samo jednim ili dva kandidata prikazuje se upravo toliko kartica.
7. Simulirati neuspjeh samo poziva preporuka ili neispravan odgovor: sekcija se
   skriva, kategorije ostaju dostupne, nema poruke greške za preporuke, a log postoji.
8. Iz Pretrage/Favorita vratiti se na početni tab i provjeriti novo dohvaćanje.
   Povratak s detalja ili kategorije na početnu i povratak aplikacije iz pozadine
   također osvježavaju podatke.
