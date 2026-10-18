# Phase 6: Monetizace a vydání na market

> Plán. App zůstává zdarma, bez reklam; platí se jen za extra obsah (IAP). Nic placeného
> nesmí dávat výhodu v multiplayeru. Rozhodnutí v tabulkách jsou návrh — po schválení
> platí jako uzavřená. Výchozí stav: `main` v0.8.0-alpha.1 (295 testů).

## Stav dnes (z kódu)

| Oblast | Co je | Důsledek pro monetizaci |
|---|---|---|
| Flotily (skiny) | 10 flotil v `FleetSkin`, všechny zdarma, výběr v Comcenteru | Hotový kosmetický obsah, chybí jen zámek a cena |
| Manévry | Katalog s tiery `starter/basic/advanced/signature/pack`, balíček `ace` (Spirála), `FleetProgressNotifier.grantPack` | Datový model pro IAP balíčky existuje, nákup je jen debug tlačítko |
| Kredity | Vydělávají se jen v single playeru, AI flotila se drží v „gumě“ u hráčovy | Prodej kreditů by nebyl pay-to-win v MP, ale pokřivil by progres; nedoporučuji na start |
| Progres | `shared_preferences`, jeden blob na flotilu, bez účtu | Nákupy se musí obnovovat ze storu (Restore purchases), ne z lokálního stavu |
| Supabase | Anon key, bez auth, RLS: kdokoliv může číst i přepsat kteroukoliv hru | Před veřejným vydáním nutno zpřísnit |
| Android | `applicationId com.ol1n.orbitronTactics`, release podepsaný **debug** klíčem, APK | Nutný upload keystore, AAB, verze 1.0.0 |
| iOS | Projekt existuje, `ExportOptions.plist` | Potřeba Apple Developer účet, bundle id, StoreKit konfigurace |
| Windows | V README jako podporovaný, adresář `windows/` v repu není | Pro store nepodstatné; z README buď vyhodit, nebo doplnit |
| Telemetrie | Žádný crash reporting, žádná analytika | Bez nich nejde ladit konverzi ani pády po vydání |
| Jazyk | UI anglicky | Pro CZ trh doplnit češtinu (není blocker) |
| Zvuk a grafika | Vlastní (tools/battle_audio, tools/fleet_art) | Žádné licenční riziko pro prodej |

## Zásady

1. **Zdarma je celá hra**: všechny režimy, všechny obtížnosti, všechny jednotky, pravidla,
   základní flotily a všechny manévry odemykatelné hrou. Apple i Google to vyžadují pro
   „free with IAP“ a hráči to odpouští.
2. **Placené je jen navíc**: vzhled (flotily, hudba, arény) a manévry, které jsou
   *sidegrade*, ne upgrade. Balíčkový manévr má mít stejný rozpočet síly jako podpisový.
3. **Žádný prodej kreditů ani zrychlení** na start. Případný „booster“ až po vyhodnocení
   dat (viz Fáze 4).
4. **Žádné reklamy.** Odpadá consent SDK (GDPR/UMP), Data safety je jednodušší, review
   rychlejší. Rewarded video za kredity nechat jako páku do zásoby.
5. **Vše non-consumable** (jednorázové, obnovitelné). Žádné předplatné na start.

## Katalog IAP

### Vlna 1 (součást vydání 1.0)

| SKU (product id) | Obsah | Typ | Cena (EUR/CZK) |
|---|---|---|---|
| `fleet.<slug>` × 6 | Jedna prémiová flotila (6 lodí × 2 barvy) | non-consumable | 1,99 € / 49 Kč |
| `fleet.bundle_all` | Všech 6 prémiových flotil + každá další vydaná | non-consumable | 6,99 € / 179 Kč |
| `maneuvers.ace` | Balíček Ace: Spirála pro všechny lodě (už v katalogu) | non-consumable | 2,99 € / 79 Kč |
| `commander` | Vše výše + budoucí flotily a manévrové balíčky, „supporter“ odznak u jména v lobby | non-consumable | 9,99 € / 249 Kč |

Rozdělení flotil: **zdarma** Vanguard (fallback), Star Nomads, Iron Armada, Void Hive
(létají na nich AI obtížnosti, hráč je stejně vidí). **Prémiové** Solar Crusade, Neon
Runners, Crystal Choir, Ronin Blades, Atomic Age, Abyssal Tide. Alfa testerům nic
nemizí: kdo má uložený `skin` prémiové flotily, dostane ji grandfatherem (viz krok 3).

### Vlna 2 (1.1–1.3, po vydání, po jednom za měsíc)

| SKU | Obsah | Cena |
|---|---|---|
| `maneuvers.phantom` | Nová rodina: Přízrak — krátká neviditelnost místo nedotknutelného okna, bez výstřelů | 2,99 € |
| `maneuvers.striker` | Nová rodina: Úder — dvojitý průlet s dávkou, dlouhý cooldown energie | 2,99 € |
| `music.<pack>` | Alternativní sada 6 bitevních témat (vygenerovaná `tools/battle_audio`), výběr v nastavení | 0,99 € |
| `fleet.<nový slug>` | Nová flotila každý měsíc (12 ks sprite art přes `tools/fleet_art`), v `bundle_all` i `commander` zdarma | 1,99 € |

### Vlna 3 (podle dat)

- **Vzhled desky a arény**: téma šachovnice (barvy, mocenská pole), pozadí arény, varianta
  explozí. Vyžaduje nový systém témat v `features/game` a `BattleArenaPainter`.
- **Profil v lobby**: avatar lodě, rámeček, titul. Zdarma základní, prémiové v `commander`.
- **Credit booster** (consumable nebo 7denní), jen pokud data ukáží, že hráči progres
  v Comcenteru brzdí a konverze kosmetiky je nízká.

Ceny: Google i Apple berou 15 % do 1 M USD/rok (Small Business Program / Play 15 %),
oba jsou merchant of record, DPH v EU odvádí store. Aktivně nastavit cenové tiery pro
CZK, ne nechat auto‑převod.

## Co je potřeba přidat

### A. Infrastruktura nákupů

| # | Krok | Poznámka |
|---|---|---|
| A1 | Knihovna: **RevenueCat** (`purchases_flutter`) | Zdarma do 2 500 USD MTR, dělá validaci účtenek, restore, entitlementy pro obě platformy bez vlastního backendu. Alternativa `in_app_purchase` + Supabase Edge Function pro ověření účtenek = o 1–2 týdny víc práce. |
| A2 | `Entitlements` model + `EntitlementsStore` | Oddělený od `FleetProgress` (ten je per flotila, nákupy jsou per zařízení/účet). Klíče: `fleets: Set<slug>`, `maneuverPacks: Set<id>`, `commander: bool`. Cache v `shared_preferences`, při startu a po nákupu sync z RevenueCat; offline platí cache. |
| A3 | `FleetSkin.isPremium` + `productId` | Comcenter: zamčené karty se zámkem a cenou, tap otevře nákupní sheet; po nákupu `setSkin`. Test `fleet_skin_test` rozšířit o konzistenci s produkty. |
| A4 | Manévry: `PackUnlock` → nákup | V `maneuver_card.dart` nahradit debug „Odemknout balíček“ reálným nákupem; po úspěchu `grantPack(id)` pro hráčovu flotilu. `grantPack` volat i při restore (idempotentní, `learn` jen přidává). |
| A5 | **Restore purchases** tlačítko v Comcenteru | Apple review ho vyžaduje. |
| A6 | Nákupní sheet (jedna obrazovka) | Název, co obsahuje, náhled (sprite lodí / animace manévru), cena ze storu (lokalizovaná), stav načítání, chyby. |
| A7 | Testování | Play: license testers + interní trať; iOS: StoreKit Configuration file + sandbox účet. Testy: `Entitlements` round‑trip, gating skinů, grandfather alfa skinu. |
| A8 | Grandfather | Při prvním startu s A2: pokud `FleetProgress.skin` je prémiová flotila a entitlement chybí, zapsat ji lokálně jako „vlastněná (legacy)“. |

### B. Blokery vydání (bez ohledu na IAP)

| # | Krok |
|---|---|
| B1 | Android: upload keystore, `signingConfigs.release`, klíče mimo repo (`key.properties`), build **AAB**, `versionName 1.0.0`, `versionCode` 10+. targetSdk na aktuální požadavek Play. Zkontrolovat `applicationId` (velké „T“ v `orbitronTactics` je legální, ale už se nedá změnit — rozhodnout teď). |
| B2 | **Zásady ochrany soukromí** (URL): sbírá se jméno hráče, IP (Supabase), ID nákupů, crash logy. Google Data safety + Apple App Privacy vyplnit shodně. |
| B3 | Supabase: zapnout **anonymous sign‑in**, do `games` přidat `white_uid/black_uid`, RLS: insert jen s vlastním uid, update jen hráči té hry, select jen `waiting` nebo vlastní hry. Cron na mazání `waiting` her starších 10 min a `finished` starších dne. Protokolová verze v Broadcast zprávách, aby se nespárovaly dvě verze app. |
| B4 | Crash reporting + minimální analytika: **Sentry** (bez Google závislostí, funguje na obou platformách). Události: `game_started(mode, difficulty)`, `battle_result`, `store_opened`, `purchase_started/completed/failed`, `restore`. Nic osobního. |
| B5 | **Google Play closed testing**: osobní vývojářský účet musí mít 12 testerů přihlášených nepřetržitě 14 dní, než jde do produkce. Toto je kritická cesta — spustit **první den**, ještě bez IAP (IAP se přidá dalším buildem na stejné trati). |
| B6 | Apple: Developer účet (99 USD/rok), bundle id, App Store Connect záznam, IAP produkty schválené spolu s prvním buildem, review notes jak otestovat multiplayer (dvě zařízení, nebo single player jako výchozí). Age rating 4+ (stylizované exploze lodí, bez krve). |
| B7 | Store assety: ikona (je), 6–8 screenshotů na telefon + tablet, feature graphic 1024×500, krátký a dlouhý popis CZ/EN, video z `GALLERY.md`. |
| B8 | Onboarding: pravidla jsou nestandardní (pěšec útočí jen diagonálně, mocenská pole, poslední bojovník). Jedna obrazovka „Jak hrát“ + první bitva s nápovědou k ovládání a gestům. Bez toho první hráči odejdou dřív, než uvidí obchod. |
| B9 | Lokalizace CZ (`flutter_localizations` + `intl`, ARB). Nutné pro CZ store listing, ne pro review. |
| B10 | README/CLAUDE.md: Windows buď zprovoznit, nebo odstranit z tabulky platforem. |

### C. Ekonomika a férovost

- Balíčkové manévry projít stejným self‑play testem jako Hard vs Medium (`--tags slow`):
  AI s balíčkem vs bez něj nesmí mít winrate nad ~55 %.
- Prémiové flotily nesmí měnit `hitHalfWidth`, velikost sprite ani rychlost — jen obrázek.
- Kreditové ceny nechat; obchod nabízet ve chvíli zájmu: po vyhrané bitvě toast
  „Nová flotila k vidění v Comcenteru“, v Comcenteru záložka **Obchod** vedle Units a Maneuvers.

## Fáze a odhad

| Fáze | Obsah | Odhad |
|---|---|---|
| 0. Store‑ready | B1, B2, B3, B4, B5 (zahájit closed testing), B10 | 1 týden |
| 1. IAP | A1–A8, B8 (onboarding), B7 (assety) | 2 týdny, běží souběžně se 14 dny testingu |
| 2. Vydání 1.0 | Play produkce po uplynutí testingu; iOS submit hned po (B6); B9 pokud stihne | po ~3 týdnech od startu |
| 3. Obsah | Vlna 2: měsíčně flotila, čtvrtletně manévrový balíček, hudební pack | průběžně |
| 4. Vyhodnocení | Konverze (cíl 1–3 % platících), nejprodávanější SKU, retention D1/D7; rozhodnout o Vlně 3 a boosterech | 1–2 měsíce po vydání |

## Pořadí commitů pro Fázi 0–1

1. `chore(android)`: release signing, AAB, verze 1.0.0, targetSdk.
2. `feat(supabase)`: anonymous auth, RLS podle uid, cleanup cron, protokolová verze.
3. `feat(telemetry)`: Sentry, události obchodu a her.
4. `feat(entitlements)`: model, store, grandfather, testy.
5. `feat(store)`: RevenueCat, nákupní sheet, Restore, zámky skinů, nákup balíčku Ace.
6. `feat(onboarding)`: Jak hrát + nápověda v první bitvě.
7. `docs`: zásady soukromí (web/GitHub Pages), README, CHANGELOG, CLAUDE.md.

## Otevřené otázky

1. RevenueCat vs vlastní ověření přes Supabase Edge Function? (Návrh: RevenueCat.)
2. Zdarma 4 flotily a 6 placených, nebo nechat všech 10 zdarma a zpoplatnit až nové? (Návrh: 4 + 6 — jinak Vlna 1 nemá co prodávat.)
3. Prodávat flotily i jednotlivě, nebo jen bundle? (Návrh: obojí; jednotlivé kusy táhnou bundle.)
4. Cílit iOS do 1.0, nebo až po Play? (Návrh: Play první kvůli 14 dnům testingu, iOS hned po.)
