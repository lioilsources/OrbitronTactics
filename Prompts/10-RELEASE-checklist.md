# Release 1.0 — co zbývá udělat s účty a klíči

> Předávací checklist k plánu `09-PLAN-monetizace.md`. Kód je hotový na větvi
> `claude/plan-monetizace` (Android podpis, Supabase RLS, telemetrie, obchod,
> onboarding). Tady jsou kroky, které potřebují tvoje účty, klíče nebo Mac.
> Od té doby přibyly: balíčky manévrů Phantom a Striker, hudba Retro Arcade,
> čeština v aplikaci a screenshoty do storu. Produktů je teď **12**.
>
> **Oprava 20/11/2026:** sekce 2, 6 a 7 přepsané podle existující release
> pipeline (`.github/workflows/release-*.yml` podepisuje a nahrává sám,
> spouští ho tag `v*`). Ruční postup zůstal jako záloha. Zbytek plánu je
> v `11-PLAN-release-1.0.md`.
>
> Pro Claude v lokálním terminálu: postupuj po sekcích, nic z toho necommituj
> kromě úprav označených **(commit)**. Klíče patří do `release.json` a
> `android/key.properties`, oba jsou v `.gitignore`.

Stav větve: `flutter analyze` čistý, `flutter test --exclude-tags slow` 344
zelených (4 přeskočené jsou generátor screenshotů), `flutter build apk --release` i `flutter build appbundle --release`
(s testovacím upload klíčem) prošly na Linuxu s Flutter 3.41.9. iOS build
neověřený (chybí Mac).

## 1. Supabase (nejdřív, jinak online hra přestane fungovat)

1. Dashboard → Authentication → Sign In / Providers → **Allow anonymous
   sign-ins: ON**.
2. Migrace:
   ```bash
   supabase link --project-ref sgyqrkaajmgpyutmmyqj
   supabase db push
   ```
   Pouští `20261108000001_games_owned_by_players.sql` a
   `20261108000002_app_events.sql`. První smaže staré hry bez hráčů.
3. Ověř v SQL editoru:
   ```sql
   select jobname, schedule from cron.job;   -- delete-stale-games, delete-old-app-events
   select count(*) from public.app_events;   -- po spuštění nové verze roste
   ```
   Když `cron.job` neexistuje: Database → Extensions → zapni `pg_cron` a
   spusť z migrace blok `do $$ ... $$` znovu.
4. Pozor: alfa buildy 0.8 a starší se po migraci online nepřipojí (nemají
   přihlášení). Lokální režimy fungují dál.

## 2. Android upload klíč

Upload klíč je v GitHub secrets (`ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`;
nastavuje je `setup-gh-secrets.sh` z repa Distribution). Oldřich potvrdil
20/11/2026, že je to upload klíč pro Play. `release-android.yml` z něj
vytvoří `android/app/release.keystore` a `android/key.properties` a Gradle
jím podepíše AAB i APK.

**Pozor při prvním tagu po sloučení:** do té doby se release podepisoval
debug klíčem runneru. Testeři z Firebase App Distribution musí starou verzi
odinstalovat a přijdou o postup flotily (je jen v `shared_preferences`).

Záloha, build na vlastním stroji:
```bash
cp android/key.properties.example android/key.properties   # vyplň hesla
# storeFile ukazuje na keystore relativně k android/app/
```

## 3. Sentry

sentry.io → nový projekt Flutter → zkopíruj DSN do `release.json`
(`SENTRY_DSN`). Bez DSN aplikace běží bez Sentry.

## 4. Google Play Console

1. Vytvoř aplikaci, balíček **`com.ol1n.orbitronTactics`** (po prvním
   uploadu už nejde změnit).
2. Play App Signing: nech Google spravovat podpisový klíč, nahráváš
   upload klíčem z kroku 2.
3. Účet je firemní (organizace): podmínka 12 testerů na 14 dní neplatí,
   vydává se rovnou do produkce. Interní test pro vlastní kontrolu stačí.
4. Monetize → In-app products: založ 12 jednorázových produktů podle
   tabulky v `docs/store-listing.md` (id musí sedět přesně), každý za
   USD 0,99 (ostatní měny automatický přepočet), stav Active.
5. Settings → License testing: přidej svůj Google účet a testery
   (nákupy zdarma, testovací karta).
6. Data safety, Content rating, Target audience 13+: odpovědi jsou
   v `docs/store-listing.md`.
7. Zásady soukromí: vyplň v `docs/privacy-policy.md` jméno, e-mail a datum
   **(commit)** a zveřejni na veřejné URL (GitHub Pages z `docs/`, nebo
   jakákoli stránka). URL vlož do Play Console i App Store Connect.

## 5. RevenueCat

1. app.revenuecat.com → nový projekt → **Google Play app**: package name
   výše, service account JSON (návod RevenueCat „Google Play service
   credentials“; oprávnění se propisují až 36 h).
2. **App Store app**: bundle id `com.ol1n.orbitronTactics`, In-App
   Purchase Key z App Store Connect.
3. Products → Import: všech 12 produktů z obou storů. **Entitlements ani
   Offerings nejsou potřeba**, aplikace mapuje id produktů na obsah sama.
4. API keys → public SDK keys `goog_...` a `appl_...` do `release.json`.

## 6. Klíče do buildu (GitHub secrets)

Release workflow předává `flutter build` tyto secrets přes `--dart-define`.
Prázdný secret = služba vypnutá, build projde:

| Secret | Odkud |
|---|---|
| `SENTRY_DSN` | sekce 3 |
| `REVENUECAT_GOOGLE_KEY` | sekce 5, `goog_...` |
| `REVENUECAT_APPLE_KEY` | sekce 5, `appl_...` |

```bash
gh secret set SENTRY_DSN            # hodnotu vlož na výzvu, ne do příkazu
gh secret set REVENUECAT_GOOGLE_KEY
gh secret set REVENUECAT_APPLE_KEY
```
`SUPABASE_URL` a `SUPABASE_ANON_KEY` nejsou potřeba, výchozí hodnoty
v kódu míří na stávající projekt.

## 7. Vydání tagem

1. Apple Developer Program, App ID `com.ol1n.orbitronTactics` s capability
   **In-App Purchase**; provisioning profil a certifikát jsou v secrets
   (`IOS_*`, `APP_STORE_CONNECT_API_*`, z repa Distribution).
2. App Store Connect: nová aplikace, 12 In-App Purchases (Non-Consumable,
   stejná id), každý s review screenshotem; odeslat spolu s prvním buildem.
3. `git tag v1.0.0 && git push origin v1.0.0` spustí oba workflow. Verze
   se bere z tagu, číslo buildu je číslo běhu.
   - Android: AAB a APK do GitHub Release a Firebase App Distribution.
     AAB nahraj do Play Console.
   - iOS: IPA do TestFlightu a GitHub Release.
4. Sandbox tester v App Store Connect → Users and Access → Sandbox.
5. Review notes: „Single player works offline. Online play needs two
   devices. Purchases: Comcenter (top right) → Store tab; Restore purchases
   at the bottom.“

Záloha, build na vlastním stroji:
```bash
cp release.example.json release.json      # vyplň klíče
flutter build appbundle --release --dart-define-from-file=release.json
cd ios && pod install --repo-update && cd ..
flutter build ipa --release --dart-define-from-file=release.json
```

## 8. Test před odesláním

| Scénář | Očekávání |
|---|---|
| Debug build (`flutter run`) | Obchod prodává zdarma s cenou „FREE (debug)“ |
| Release bez RevenueCat klíče | Store tab: „The store is not available on this build“ |
| License tester koupí Solar Crusade | Flotila odemčená a vybraná, `app_events` má `purchase` s `purchased` |
| Refund v Play Console, restart aplikace | Flotila znovu zamčená, letí Vanguard |
| Reinstalace, Restore purchases | Nákupy zpět |
| Balíček Ace, Phantom, Striker | Spirála, Fantom a Nálet u všech lodí v záložce Maneuvers |
| Hudba Retro Arcade | V Store tabu volba hudby; po koupi hraje v bitvě, po refundu zase standardní |
| Telefon s češtinou / jiným jazykem | Čeština / angličtina |
| Start offline | Hra jede, obchod bez cen, koupené věci zůstávají |
| Alfa tester s prémiovou flotilou | Po aktualizaci ji má dál (legacy) |
| Dvě zařízení, online hra | Lobby ukáže hru, druhý se připojí; třetí ji už nevidí |
| První spuštění | Obrazovka How to play; první bitva má nápovědu ovládání |

## 9. Store assety

Hotové v `docs/store/`: 7 screenshotů telefonu v EN a CS a feature graphic
1024×500 v EN a CS (generuje je `STORE_SCREENSHOTS=1 flutter test
test/store_screenshots`). Ikona 512×512 je `assets/icon/icon.png`, texty
jsou v `docs/store-listing.md`. Chybí jen screenshoty tabletů (nepovinné).
Lepší by byly screenshoty z reálného zařízení; tyhle jsou z testu.

## Co z plánu není hotové

- **Odznak supportera v lobby** u Commander Edition: vypuštěn, šel by
  podvrhnout z klienta; Commander dává všechen současný i budoucí obsah.
- **Vlna 3** (témata desky, profil v lobby, booster kreditů) podle plánu
  po vydání. Nové flotily potřebují sprity, nástroj na ně v repu není.
- **Hudba Retro Arcade** je syntetizovaná skriptem, ne generovaná modelem;
  poslechni ji před vydáním (`tools/battle_audio/chiptune.py`).
- **Windows**: v repu není `windows/`, z README a CLAUDE.md jsem ho vyřadil.
