# Phase 7: Dotažení do vydání 1.0 — zadání pro Opus

> Navazuje na `09-PLAN-monetizace.md` (plán) a `10-RELEASE-checklist.md` (kroky
> s účty). Kód monetizace je hotový na větvi `claude/plan-monetizace`, 12 commitů
> nad `main`, bez pull requestu. Tohle zadání říká, co je rozbité, co je
> neověřené a v jakém pořadí to dotáhnout. Fakta níže jsou ověřená
> k 13/11/2026; co ověřené není, je tak označené.

## Kde to stojí

| Oblast | Stav | Jak je to ověřené |
|---|---|---|
| Analyzer, testy | čisté, 344 testů (4 přeskočené = generátor screenshotů) | lokálně i CI job „Tests & Analysis“ |
| Android debug build | prochází | CI |
| Android release APK a AAB | prochází, AAB podepsaný upload klíčem | lokálně s testovacím keystorem |
| Zarovnání nativních knihoven na 16 KB | v pořádku (všechny `.so` ≥ 0x4000) | `readelf` + `zipalign -c -P 16` na release APK |
| **iOS build** | **padá** | CI job „iOS Debug Build“, běhy 43 a 44 |
| Supabase migrace | scénáře RLS prošly | lokální Postgres 16 s napodobeným `auth.uid()`, ne skutečný projekt |
| Obchod, nákupy | jen `DebugPurchaseService` a testy | RevenueCat nikdy neběžel proti storu |
| Zvuk hudebního balíčku, ukázka v obchodě | **neposlechnuto, nespuštěno** | testy SoLoud nenačtou; kontrolovány jen hlasitost, ořez, šev smyčky |
| Čeština | úplná podle testu, texty psal model | `test/l10n/l10n_test.dart` |
| Na skutečném zařízení | **nic z této větve neběželo** | — |

Otevřený PR #8 (`claude/maneuver-dump-tool`, jen `tools/dump_maneuvers.dart`
a řádek v `CLAUDE.md`) s touto větví nesouvisí; při slučování hrozí jen konflikt
v `CLAUDE.md`. Skript vypisuje katalog manévrů, takže po sloučení ukáže i nové
rodiny `phantom` a `strafe`.

## Pravidla práce

- Každý krok samostatný commit, po každém `flutter analyze` bez nálezů
  a `flutter test --exclude-tags slow` zelené. Flutter 3.41.x (CI ho pinuje).
- **Nepouštěj `dart format` na celé soubory.** Repo není formátované aktuálním
  formátovačem, přepíše stovky řádků. Odsazuj ručně.
- Nové texty v UI patří do `lib/l10n/app_en.arb` i `app_cs.arb`, pak
  `flutter gen-l10n` (generované soubory se commitují). Text z katalogu
  (manévr, balíček) má český protějšek v `lib/l10n/content_cs.dart`.
- Klíče a hesla nikdy do repa: `release.json`, `android/key.properties`
  a keystore jsou v `.gitignore`.
- Po změně UI přegeneruj screenshoty:
  `STORE_SCREENSHOTS=1 flutter test test/store_screenshots`.

## Krok 0 — rozhodnutí, která potřebuju od Oldřicha

Zeptej se hned na začátku jednou zprávou; na odpovědích závisí kroky 3, 5 a 7,
ostatní na ně nečekají.

1. **Orientace šachovnice.** Bílý (lokální hráč) má figurky nahoře a svou lištu
   dole; zadní řada bílého je řada 0 a `_visualRow` ji kreslí nahoru. Je to tak
   už na `main` a `06-RC-alfa-001.md` přitom říká „White's perspective at the
   bottom“. Otočit? Viz krok 3.
2. **Zásady soukromí:** jméno provozovatele, kontaktní e-mail a URL, kde budou
   viset (`docs/privacy-policy.md` má zástupné `[DEVELOPER NAME]`,
   `[CONTACT EMAIL]`, `[DATE]`).
3. **Ceny** v `docs/store-listing.md` (12 produktů) — platí?
4. **Keystore v GitHub secrets** (`ANDROID_KEYSTORE_BASE64`) — je to klíč, který
   má být upload klíčem pro Play? Viz krok 2.
5. **iPad:** projekt má `TARGETED_DEVICE_FAMILY = "1,2"`, App Store pak chce
   i screenshoty iPadu. Nechat iPad, nebo jen iPhone?
6. **`app-release.apk` v kořeni repa** (50 MB, alfa z února, verzovaný) —
   smazat?

## Krok 1 — opravit iOS build (blokuje vše na iOS)

**Diagnóza** (log jobu 129426548286): `pod install` skončí na
`None of your spec sources contain a spec satisfying the dependency:
PurchasesHybridCommon (= 20.3.0)`. Verzovaný `ios/Podfile.lock` je z doby před
RevenueCat a Sentry (neobsahuje ani jeden) a lokální kopie spec repa na runneru
je starší než vydání `PurchasesHybridCommon 20.3.0`.

1. Na Macu: `cd ios && pod install --repo-update`, commitnout nový
   `Podfile.lock`.
2. V `ios/Podfile` odkomentovat `platform :ios, '13.0'` (dnes ho CocoaPods
   jen hádá a varuje; `purchases_flutter` chce 13.0, projekt má 13.0).
3. V `.github/workflows/ci.yml` (job `build-ios-debug`) přidat před build krok
   `pod repo update`, nebo `cd ios && pod install --repo-update`.
   V `release-ios.yml` změnit `pod install` na `pod install --repo-update`.
4. Hotovo, až je CI job „iOS Debug Build (Simulator)“ zelený.

Nemáš-li Mac, krok 3 sám nejspíš stačí (CI lock dopočítá), ale `Podfile.lock`
pak zůstane v repu zastaralý — nech ho z CI nahrát jako artefakt a commitni.

Při první nahrávce do App Store Connect čekej e-maily o privacy manifestech
(ITMS-91053). RevenueCat i Sentry svůj manifest nesou; aplikace vlastní
`PrivacyInfo.xcprivacy` nemá. Přidej ho, jen pokud si o něj Apple řekne.
`ITSAppUsesNonExemptEncryption = false` v `Info.plist` už je.

## Krok 2 — release workflow neumí předat klíče (blokuje obchod v buildu)

`release-android.yml` a `release-ios.yml` staví bez `--dart-define`. Build
z nich má obchod ve stavu „Store not available“ a žádný Sentry. Navíc
`10-RELEASE-checklist.md` popisuje ruční keystore a „iOS na Macu“, přestože
pipeline obojí už dělá — checklist jsem psal, aniž bych workflow četl.

1. Do obou workflow přidat k `flutter build` (Android: `appbundle` i `apk`;
   iOS: `flutter build ios --release --no-codesign`, defines se přes
   `Generated.xcconfig` dostanou i do `xcodebuild archive`):
   ```
   --dart-define=SENTRY_DSN=${{ secrets.SENTRY_DSN }}
   --dart-define=REVENUECAT_GOOGLE_KEY=${{ secrets.REVENUECAT_GOOGLE_KEY }}
   --dart-define=REVENUECAT_APPLE_KEY=${{ secrets.REVENUECAT_APPLE_KEY }}
   ```
   Prázdný secret = služba vypnutá, build projde. Secrets založí Oldřich.
2. **Pinovat Flutter** v release workflow na `3.41.x` jako v CI. Dnes berou
   nejnovější stable; `sentry_flutter` 9.x a `flutter_soloud` 4.x jsou zvolené
   pro 3.41 (viz CLAUDE.md, Dependencies).
3. **Pozor na změnu podpisu.** Na `main` Gradle `key.properties` ignoroval
   a release se podepisoval debug klíčem runneru. Tahle větev ho čte
   (`storeFile=release.keystore` relativně k `android/app/` sedí s workflow).
   První build po sloučení tedy bude mít jiný certifikát: testeři z Firebase
   App Distribution musí starou verzi odinstalovat a **přijdou o postup flotily**
   (je jen v `shared_preferences`). Řekni to Oldřichovi před tagem.
4. Opravit `10-RELEASE-checklist.md`: sekce 2 (keystore), 6 (build) a 7 (iOS)
   přepsat na „secrets + tag `v*`“, ruční postup nechat jako zálohu.
5. Po kroku 1 a 2 ověřit na buildu z workflow: záložka Store ukazuje ceny ze
   storu, ne „—“.

## Krok 3 — orientace šachovnice (po odpovědi z kroku 0)

Pokud otočit: bílý dole znamená kreslit řadu 0 dole. `_visualRow`/`_vRow` je ve
třech souborech (`game_board.dart`, `board_background_painter.dart`,
`board_overlay_painter.dart`) a zpětný převod v `_handleTap`; dnes je to
`flipBoard ? 7 - r : r`, po změně `flipBoard ? r : 7 - r`. Sloupce zvaž zvlášť
(z pohledu bílého má být sloupec 0 vlevo; při otočení pro černého se zrcadlí).
Animace tahu a „duch“ braného kamene používají tytéž funkce — projdi je.
Přidej widgetový test: v single playeru za bílého je bílý král ve spodní
polovině desky a klepnutí na pole vrátí správnou logickou pozici.
Pak přegeneruj screenshoty.

## Krok 4 — slabá místa v kódu této větve

Seřazeno podle dopadu. U každého je navržená oprava; kde je to produktové
rozhodnutí, je to řečeno.

| # | Problém | Kde | Návrh |
|---|---|---|---|
| 1 | Čekající platba (`PurchasePending`) dorazí až při příštím startu aplikace | `EntitlementsNotifier`, `RevenueCatPurchaseService` | Přidat `Purchases.addCustomerInfoUpdateListener` → `_apply`; do `PurchaseService` stream změn, v debug a nedostupné službě prázdný |
| 2 | Vrácený balíček manévrů zůstane naučený i vyzbrojený | `EntitlementsNotifier._apply` jen přidává (`grantPack`) | Nemazat z postupu; filtrovat při použití: `AiOpponentController.maneuversFor` a Comcenter vynechají manévry s `PackUnlock`, na které není nárok |
| 3 | `sync()` nahrazuje vlastněné produkty tím, co vrátí RevenueCat. Na Androidu po reinstalaci může vrátit prázdno, dokud hráč nedá Restore, a prémiová flotila spadne na Vanguard | `EntitlementsNotifier.sync/_apply` | Ověřit na zařízení. Pokud se to děje, při prvním startu bez cache zavolat jednou `restore()` (na Androidu bez dialogu; na iOS ne, vyvolá přihlášení) |
| 4 | Každý start aplikace založí anonymního uživatele v Supabase, i když hráč nikdy nehraje online (kvůli `app_opened`) | `SupabaseTelemetry.ensureSignedIn` | Rozhodnutí: buď přijmout (limit MAU tarifu), nebo události před přihlášením držet ve frontě a poslat až při první online akci. Není vypínač telemetrie — zvaž přepínač v Comcenteru |
| 5 | Broadcast kanál `game:<id>` je veřejný: kdo zná id hry, poslouchá a posílá tahy | `SupabaseGameTransport` | Po vydání: private channel + Realtime Authorization (RLS na `realtime.messages` podle `white_uid`/`black_uid`) |
| 6 | Bitva nemá časový limit; dva piloti Hard se navzájem netrefí nikdy (zjištěno v balančním testu, 180 s bez zásahu) | `BattleEngine`, `BattleAi` | Produktové rozhodnutí: „sudden death“ po N sekundách (zmenšit zónu úhybu nebo zrychlit střely). V multiplayeru dva opatrní hráči mohou hru zablokovat |
| 7 | Výchozí jména hráčů se pro zobrazení překládají porovnáním anglického řetězce | `_playerLabel` v `game_screen.dart` | Nést v `Player` příznak (např. `userId` `local-white`, `ai-*`) a překládat podle něj |
| 8 | Mrtvý kód: `UpgradeRepository` čte tabulku `user_upgrades`, která v migracích není, a nikdo ho nevolá | `lib/features/comcenter/data/upgrade_repository.dart` | Smazat |
| 9 | `GameRepository.finishGame` nikdo nevolá; dohrané hry visí jako `playing` do úklidu po 24 h | `game_repository.dart` | Zavolat při konci online hry, nebo metodu smazat |
| 10 | Hostitel online hry neposílá `game_started` (jen připojený hráč), záměrně kvůli dvojímu počítání | `lobby_screen.dart` | Nechat, jen o tom vědět při čtení čísel |

Po úpravách `BattleAi` nebo katalogu pusť i `flutter test --tags slow`. Od
změny konstruktoru `BattleAi` běžel jen `maneuver_pack_balance_test`, celý
self-play Hard vs Medium ne — **neověřeno**.

## Krok 5 — Supabase na ostro (potřebuje účet)

Pořadí je důležité; staré alfa buildy se po migraci online nepřipojí.

1. Dashboard: zapnout anonymous sign-ins.
2. `supabase migration list` proti projektu. První migrace
   (`20260207000001_create_games`) mohla být kdysi puštěná ručně; pokud ji
   CLI vede jako neaplikovanou, nejdřív
   `supabase migration repair --status applied 20260207000001`.
3. `supabase db push` (dvě nové migrace). Zkontrolovat `select * from cron.job`.
4. Dvě zařízení: založit hru, připojit se, dohrát. Třetí účet hru v lobby
   nevidí po připojení druhého. Lobby stream (`watchWaitingGames`) jde přes
   Realtime s RLS — to lokálně ověřit nešlo.
5. V tabulce `app_events` přibývají řádky.

## Krok 6 — ověření na zařízení

Projít tabulku „Test před odesláním“ v `10-RELEASE-checklist.md` a navíc to, co
dosud nikdy neběželo:

- **Hudba Retro Arcade:** poslechnout všech šest smyček v bitvě i ukázku
  v obchodě (`BattleAudio.preview`). Jsou to syntetizované pulzní vlny; pokud
  znějí lacině, uprav `tools/battle_audio/chiptune.py` (melodie jsou seedované,
  `Theme.seed`), nebo balíček vyřaď z katalogu, než půjde do storu.
- **Phantom:** loď má během okna 15 % viditelnosti. Zkontrolovat, že je to
  čitelné pro oba hráče a přes WiFi (soupeřův engine letí stejnou cestu).
- **Čeština:** projít všechny obrazovky na českém telefonu, hlavně přetékání
  delších textů (tlačítka v lobby, „VE VÝZBROJI“, „ZÍSKAT BALÍČEK“) a zkratky
  `ŽIV`/`POŠK` v kartě jednotky.
- **Onboarding:** první spuštění ukáže „Jak hrát“, první bitva nápovědu.
- **Sentry:** vyvolat testovací chybu, ověřit, že dorazí bez osobních údajů.

## Krok 7 — podklady pro story

- **Screenshoty pro App Store:** generátor dělá 1080×1920, což stačí pro Play,
  ale App Store chce 6,9" (1290×2796 nebo 1320×2868). Parametrizuj
  `_logical`/`_scale` v `test/store_screenshots/store_screenshots_test.dart`
  (430×932 při 3×) a vyrenderuj druhou sadu do `docs/store/screenshots_ios/`.
  Při ponechaném iPadu i 13" (2064×2752).
- Šachové symboly ve screenshotech jsou z DejaVu Sans; na telefonu je kreslí
  systémový font a vypadají jinak. Lepší jsou snímky ze zařízení.
- Doplnit zásady soukromí (krok 0) a zveřejnit je.
- 12 produktů v Play Console a App Store Connect, RevenueCat import —
  `10-RELEASE-checklist.md`, sekce 4 a 5.

## Krok 8 — sloučení a vydání

1. Pull request `claude/plan-monetizace` → `main` (až je CI celé zelené).
   PR #8 sloučit před ním nebo po něm, konflikt je jen v `CLAUDE.md`.
2. `pubspec.yaml`: `version: 1.0.0+1` (workflow číslo buildu přepíše
   číslem běhu; bere jen `X.Y.Z`, příponu `-alpha` zahodí).
3. Commit „Release 1.0.0-rc.1“ podle zvyku repa, tag `v1.0.0-rc.1` spustí oba
   release workflow: AAB a APK do GitHub Release a Firebase App Distribution,
   IPA do TestFlightu.
4. AAB nahrát do Play Console na closed testing. **12 testerů po 14 dní** je
   podmínka produkce u osobního účtu; čím dřív poběží, tím líp. Zvaž krok do
   workflow, který AAB nahraje rovnou (`r0adkll/upload-google-play`), až bude
   service account.
5. Po 14 dnech produkce na Play, iOS review souběžně.

## Po vydání

- **Nové flotily:** nástroj na sprity je na větvi `claude/fleet-art-tools`
  (`tools/fleet_art/`), v `main` není. Nová flotila = složka
  `assets/fleets/<slug>/` (12 PNG), položka `FleetSkin` s `premium: true`,
  složka v `pubspec.yaml`; produkt `fleet.<slug>` vznikne v `StoreCatalog` sám.
- **Další hudba:** `tools/battle_audio/gen_audio.py` na serveru SPARK umí
  udělat sadu modelem; nová sada = hodnota v `BattleMusic` + složka assetů.
- **Vlna 3** z `09-PLAN-monetizace.md` (témata desky, profil v lobby, booster
  kreditů) až podle čísel z `app_events`: konverze, nejprodávanější produkt,
  kolik hráčů otevře obchod.

## Hotovo znamená

- CI zelené včetně iOS, release workflow staví s klíči a pinovaným Flutterem.
- Build z workflow na zařízení: nákup testovacím účtem projde, Restore vrátí
  nákupy, refund flotilu zamkne, hudba hraje a zní přijatelně.
- Online hra na dvou zařízeních proti produkčnímu Supabase.
- Zásady soukromí zveřejněné, 12 produktů aktivních, closed testing běží.
- `10-RELEASE-checklist.md` odpovídá skutečné pipeline.
