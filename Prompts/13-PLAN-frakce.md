# FRAKCE_PLAN — šachové figurky jako dvě frakce + flux-dev prompty

> Handoff pro Opus (Claude Code).
> Cíl: místo černých a bílých figurek dvě na první pohled rozpoznatelné frakce („skin packy“), každá s charakterem pro všech 6 typů figurek, vygenerované přes flux-dev.
> Čeština = zadání a jména. Angličtina = všechno, co jde do promptu (bloky v `kódu` kopíruj doslova).

Stav implementace: fáze 0 (PoC Nebe × Peklo) v `tools/faction_art/`. Data z kap. 1.1, 2 a 5 jsou v `styles.yaml` a `factions.yaml`; zatím jsou v nich páry s hotovými SUBJECT větami (1, 9, 26).

Rozhodnutí Olina po PoC (15. 11. 2026):
1. **Model: Qwen-Image** (Apache 2.0), ne flux-dev. FLUX-dev kreslil v Pekle černé podstavce a má nekomerční licenci. Nastavení: 20 kroků, cfg 2.5, shift 3.1, prázdný negativní prompt. Pravidla psaní z kap. 4 platí dál.
2. **Úprava pevných bloků:** rám u věže říká „Single building“ místo „Single figure“, protože Qwen jinak přidává k věži postavičku. Siluetová věta střelce drží jen hůl, bez „or bow“.
3. **Větší figury:** král zabírá celou výšku pole, ostatní figury podle poměrů z kap. 1.1.
4. **Bez podstavce:** rám podstavec nezmiňuje a programově se nedomalovává. Strany se rozlišují barvou, motivem a obrysem.

## 0. Zadání v kostce

- **Problém:** černé figurky jsou na desce nerozpoznatelné. Žádná frakce proto nesmí být definovaná tmou.
- **Řešení:** stranu poznáš podle **barvy a motivu**, typ figurky podle **siluety**. Siluetová pravidla jsou stejná pro všechny frakce.
- **Výstup jednoho packu:** 2 strany × 6 figurek = 12 PNG s průhledností, barvy desky, manifest.
- **Stylové presety:** `KIDS` (dětské šachy, např. PrincessChess), `EPIC` (dospělejší varianta, např. Archion), `FLAT` (ikonový, pojistka čitelnosti v malé velikosti).
- **Postup:** nejdřív PoC na jednom páru (Nebe × Peklo), po schválení teprve dávka.
- **Pack 0 (levná okamžitá oprava):** klasické stauntonské tvary ve dvou ne-černých materiálech, např. zlato × tyrkysové sklo nebo jantar × nefrit. Řeší čitelnost bez nových charakterů.

## 1. Pravidla čitelnosti (závazná pro každý pack)

### 1.1 Siluetová gramatika

| Typ | Cílová výška | Obrys | Co to smí být |
|---|---|---|---|
| Král | 100 % | nejvyšší a nejmasivnější, koruna + svislý symbol (žezlo, meč, standarta) | vládce |
| Dáma | 92 % | vysoká, **vějířovitý** obrys (křídla, plášť, paprsky, ocasy, široká sukně) | vládkyně, bohyně, hrdinka |
| Střelec | 84 % | vysoký a štíhlý, **špičatý vršek**, dlouhá hůl nebo luk držený šikmo | kněz, mág, lučištník, posel |
| Kůň | 78 % | zvíře nebo jezdec **z profilu**, prohnutý krk, tvar „L“ | oř, šelma, jezdec |
| Věž | 72 % | **široká a hranatá**, plochý nebo zubatý vršek | stavba, vůz, loď, kolos — ne běžná postava |
| Pěšec | 58 % | nejmenší, kulatý, jediná malá rekvizita | voják, učeň, mládě |

Výšky se **nevynucují promptem**. Každá figurka se generuje přes celý obrázek a škáluje se až v postprocessu (kap. 6).

Fragmenty do promptu (`SIL_*`) jsou v `tools/faction_art/styles.yaml`.

### 1.2 Barvy frakcí

- Každý pár = **teplý × studený** tón. Obě strany ve středním jasu.
- „Temná“ strana má vždy sytý svítící akcent a světlý lem (rim light). Nikdy jen černá hmota.
- Bezpečné dvojice: zlatá × indigo, oranžová × modrá, žlutá × fialová, korálová × tyrkysová. Červená × zelená nesmí být jediný rozdíl (barvoslepost).
- Pod každou figurkou **barevný podstavec** v barvě strany (klidně domalovaný programově).
- Programový obrys 2–3 px: tmavý u světlé strany, světlý u tmavé. Zaručí kontrast na obou barvách polí.
- Deska: žádná čistě bílá a černá pole, dva tlumené střední tóny laděné k packu.

### 1.3 Pojistky

- Přepínač „klasické značky“: malý šachový glyf na podstavci.
- Všechny figurky se dívají lehce doprava. Pro soupeře je appka zrcadlí, takže v soubojových animacích stojí proti sobě.
- Sestavy jsou zrcadlové typ proti typu (Pegas × Ohnivý hřebec). Hodí se jako soubojové dvojice.

### 1.4 Akceptační testy

1. **Siluetový test:** alfa vyplněná jednou barvou, 64 px. Šest typů jedné strany musí být rozeznatelných.
2. **Test desky:** výchozí postavení na polích 64 px, obě barvy polí.
3. **Šedotónový test:** strany se liší i bez barvy (jas podstavce a obrysu aspoň o 30 %).
4. **Barvoslepost:** simulace deuteranopie a protanopie.
5. **Čistota:** jedna postava na obrázek, celá od hlavy po podstavec, bez textu a bez artefaktů.

## 2. Katalog frakcí s charaktery

Legenda: 🟢 bez rizika. 🟡 skutečné kultury, náboženské války nebo kolonizace: obě strany důstojně, bez karikatur, v UI ne dobro × zlo (jen „rivalové“, strana A/B), pro dětskou appku spíš vynechat. U mýtů a fantasy je první strana „světlá“. Řádky `A:` a `B:` jsou vizuální DNA strany: `paleta; materiály a motivy | base | rim`, do promptu doslova.

### 2.A Mýty a nadpřirozeno

1. **Nebe × Peklo** 🟢 — Nebe: Archanděl s plamenným mečem, Šestikřídlý seraf, Nebeská brána na oblaku, Anděl-zvěstovatel s trubkou, Pegas, Cherubín se štítkem. Peklo: Pán pekel s trojzubcem, Ďáblice s netopýřími křídly, Sopečná bašta s lávou, Pokušitel v kápi, Ohnivý hřebec, Čertík s vidlemi.
   `A: ivory, warm gold and sky blue; polished marble, white feathers, cloud wisps, halos | base: sky blue | rim: warm gold`
   `B: deep crimson and charcoal with glowing orange lava cracks; horns, obsidian, embers | base: lava orange | rim: fiery orange`
2. **Olymp × Titáni** 🟢 — Olymp: Zeus s bleskem, Héra s pávím vějířem, Chrám se sloupy, Apollón s lukem, Kentaur Cheirón, Hoplít se štítem. Titáni: Kronos se srpem, Rheia se lvy, Atlas nesoucí nebeskou klenbu, Prométheus s pochodní, Chiméra, Malý kyklop s balvanem.
   `A: white marble, laurel green and gold; Greek columns, olive wreaths, lightning | base: azure | rim: white gold`
   `B: weathered bronze and volcanic rock with teal patina; cracked stone skin, broken chains, primal fire | base: bronze | rim: molten amber`
3. **Ásgard × Ragnarök** 🟢 — Ásgard: Ódin s kopím a havrany, Freya v sokolím plášti, Thor jako rozkročený kolos s kladivem, Valkýra s kopím, Sleipnir, Einherjar se štítem. Ragnarök: Thrym, král ledových obrů; Hel, napůl živá a napůl mrtvá; Ledový obr jako chodící ledovec; Loki s hadí holí; Vlk Fenrir; Draugr.
   `A: gold, deep blue and silver; knotwork engravings, fur cloaks, runes, rainbow shimmer | base: royal blue | rim: gold`
   `B: glacier cyan and bone white with poison-green glow; ice shards, frost, serpent scales | base: icy cyan | rim: pale green`
4. **Hórus × Seth** 🟢 — Hórus se sokolí hlavou, Isis s rozepjatými křídly, Obelisk s pylonem, Thovt s ibisí hlavou a svitkem, Kráčející sfinga, Strážce s ankhem. Seth, pán pouště; Sachmet se lví hlavou; Písečný kolos; Apop, vztyčený had chaosu; Nilský krokodýl; Mumie.
   `A: turquoise, lapis blue and gold; white linen, falcon wings, sun discs, hieroglyphic ornaments | base: lapis blue | rim: sun gold`
   `B: desert red and ochre with violet storm glow; sand, cracked clay, scales | base: brick red | rim: violet`
5. **Bílá magie × Černá magie** 🟢 — Arcimág s křišťálovou holí, Hvězdná čarodějka, Křišťálová věž, Druid s holí, Jednorožec, Učeň s lucernou. Nekromant s lebkovou holí, Temná kněžka s havranem, Obsidiánová spirála s fialovým plamenem, Černokněžník v kápi, Havraní gryf, Homunkulus.
   `A: pearl white, gold and turquoise; crystals, star sparks, silk robes | base: turquoise | rim: soft gold`
   `B: royal purple and toxic green; smoke wisps, bones, ravens, thorny staffs | base: purple | rim: acid green`
6. **Kulatý stůl × Morgana** 🟢 — Artuš s Excaliburem, Guinevera, Hradní věž Kamelotu, Merlin, Lancelot na koni, Panoš se štítem. Mordred, Morgana le Fay, Menhir v mlze, Čarodějnice z mokřad, Zelený rytíř na koni, Žoldnéř se sekerou.
   `A: silver steel, royal red and gold; heraldic lions, polished plate armor, banners | base: red | rim: silver white`
   `B: emerald green and violet with misty glow; ravens, thorns, tarnished armor, marsh fog | base: emerald | rim: violet`
7. **Bohatýři × Kostěj** 🟢 — Kníže Rudé slunko, Vasilisa Přemoudrá, Srubová věž kremlu, Volchv s holí, Ilja Muromec na koni, Družiník s kapkovitým štítem. Kostěj Nesmrtelný, Baba Jaga v moždíři, Chaloupka na kuří nožce, Lešij, Zmej Gorynyč, Kikimora.
   `A: red, white and gold with folk embroidery; chainmail, pointed helmets, carved wood | base: red | rim: gold`
   `B: swamp green, bone and rusty iron with eerie green glow; birch bark, skulls on fence posts, mushrooms | base: moss green | rim: ghost green`
8. **Samurajové × Yōkai** 🟢 — Daimjó s válečným vějířem, Onna-bugeiša s naginatou, Hradní věž tenšu, Lučištník s dlouhým lukem, Jízdní samuraj, Ašigaru s kopím. Oni s okovaným kyjem, Kicune, Nurikabe, Tengu, Raidžú, Karakasa.
   `A: vermilion lacquer, indigo and gold; lamellar armor, silk cords, cherry blossoms, clan crests | base: indigo | rim: gold`
   `B: night violet and oni red with pale blue spirit flames; paper lanterns, masks, mist | base: violet | rim: spirit blue`

### 2.B Historie

9. **Řím × Kartágo** 🟢 — Vojevůdce s vavřínem, Bohyně Roma s kopím, Testudo, Aquilifer, Jezdec equites, Legionář se scutem. Hannibal, Královna Dídó, Válečný slon s věžičkou, Baleárský prakovník, Numidský jezdec, Libyjský kopiník.
   `A: legion red and gold on polished iron; eagles, laurel, rectangular shields, crested helmets | base: red | rim: gold`
   `B: Tyrian purple, sand and bronze; crescent-and-disc emblems, palm leaves, elephant tusks, round shields | base: purple | rim: bronze`
10. **Egypt × Asýrie** 🟢 — Faraon s dvojitou korunou, Královna s modrou korunou, Chrámový pylon, Núbijský lučištník, Dvoukolý válečný vůz, Kopiník s proutěným štítem. Král s kudrnatým vousem a tiárou, Šammuramat, Lamassu, Věštec-hvězdář, Jízdní lukostřelec, Prakovník s kónickou přilbou.
    `A: white linen, turquoise and gold; striped headcloths, lotus, papyrus | base: turquoise | rim: gold`
    `B: cobalt glazed brick, terracotta and bronze; curled beards, conical helmets, rosettes, winged reliefs | base: cobalt | rim: bronze`
11. **Řekové × Peršané** 🟢 — Leónidas, Královna Gorgó, Falanga, Pýthia z Delf, Thessalský jezdec, Hoplít. Xerxés, Artemísia, Brána všech národů, Mág s posvátným ohněm, Kosinový vůz, Nesmrtelný s proutěným štítem.
    `A: bronze and crimson cloaks with white marble; crested Corinthian helmets, round hoplon shields | base: crimson | rim: bronze gold`
    `B: saffron yellow, teal and gold; patterned robes, wicker shields, soft caps, winged-sun emblems | base: teal | rim: gold`
12. **Husité × Křižáci** 🟢 — Jan Žižka s palcátem, Praporečnice s kalichem, Bojový vůz, Kazatel s kalichem, Jízdní zeman s kuší, Cepník. Císař Zikmund, Barbora Celjská, Kamenný hrad, Kardinál-legát, Těžký rytíř na koni, Žoldnéř s halapartnou.
    `A: earthy brown, red and wheat; chalice banners, wooden wagons, flails, simple kettle helmets | base: red | rim: warm white`
    `B: steel blue and white with gold; plate armor, heraldic surcoats, plumed great helms | base: steel blue | rim: cold white`
13. **Vikingové × Anglosasové** 🟢 — Jarl, Štítonoška, Drakkar, Völva, Jezdec na huňatém koníku, Nájezdník se sekerou. Král Alfréd, Æthelflæd, Burh, Mnich-písař, Thegn na koni, Sedlák s kopím.
    `A: sea blue, rust red and weathered wood; round painted shields, fur, knotwork, dragon prows | base: sea blue | rim: icy white`
    `B: golden yellow, forest green and iron; gold-and-garnet ornaments, crested helmets, wyvern banners | base: golden yellow | rim: warm amber`
14. **Samurajové × Portugalci** 🟡 — samurajové jako č. 8. Kapitán-major, Královna z Lisabonu, Karaka, Jezuita s knihou, Jezdec-fidalgo, Arkebuzír.
    `B: burgundy velvet, cream and brass; morion helmets, puffed sleeves, ruffs, red-cross sails | base: sea green | rim: brass`
15. **Mongolové × Rytíři (Lehnice 1241)** 🟢 — Chán, Chatun, Jurta na voze, Šaman s bubnem, Jízdní lučištník, Pěší lučištník. Kníže v hrncové přilbě, Kněžna se závojem, Bergfrit, Biskup s berlou, Řádový rytíř, Pěšák s pavézou.
    `A: sky blue, leather brown and gold; fur-trimmed coats, composite bows, horsehair standards | base: sky blue | rim: gold`
    `B: white surcoats with red and silver steel; great helms, heater shields, heraldic banners | base: red | rim: silver`
16. **Osmani × Svatá liga (Vídeň 1683)** 🟡 — Sultán, Valide sultan, Obléhací dělo, Velkovezír, Sipáhí, Janičář. Jan Sobieski, Císařovna, Vídeňský bastion, Kapucín, Okřídlený husar, Mušketýr.
    `A: emerald green, crimson and gold; tulip patterns, large turbans, crescents, horsehair standards | base: emerald | rim: gold`
    `B: white, imperial yellow and steel; cuirasses, feathered wings, eagle heraldry, pikes | base: imperial yellow | rim: silver`
17. **Conquistadoři × Mayové** 🟡 — Kapitán v morionu, Královna Isabela, Karavela, Františkán, Jezdec, Rodelero. Božský král s quetzalí čelenkou, Paní Šest nebes, Stupňovitá pyramida, Kněz-hvězdář, Jaguár, Válečník s vrhačem oštěpů.
    `A: steel, burgundy and gold; morion helmets, breastplates, ragged-cross banners | base: burgundy | rim: steel white`
    `B: jade green, turquoise and red ochre; quetzal feathers, jaguar pelts, carved stone ornaments | base: jade | rim: turquoise`
18. **Kavalerie × Lakotové** 🟡 (bezpečnější náhrada: Šerifové × Psanci) — Generál, Zvědka, Pevnost, Trubač, Kavalerista, Pěšák. Náčelník, Bojovnice, Bizon, Svatý muž s dýmkou, Jezdec na mustangu, Zvěd s lukem.
    `A: navy blue and yellow with brass; slouch hats, sabers, neckerchiefs | base: navy | rim: brass yellow`
    `B: earth red, white and turquoise beadwork; buckskin, painted shields, feathers | base: earth red | rim: warm white`
19. **Piráti × Královské námořnictvo** 🟢 — Kapitán s papouškem, Pirátská královna, Galeona, Kormidelník, Pirát na mořském koníku, Plavčík. Admirál, Guvernérka, Pevnost s děly, Důstojník se sextantem, Námořní dragoun, Námořník s mušketou.
    `A: crimson, weathered wood and gold coins; tricorn hats, striped shirts, ropes, tattered sails | base: crimson | rim: gold`
    `B: navy blue, white and brass; tailored coats, epaulettes, cannons, anchors | base: navy | rim: white`
20. **Napoleon × Koalice (Slavkov 1805)** 🟢 — Napoleon, Josefína, Dělová baterie, Tambor-major, Kyrysník, Granátník. Car Alexandr, Carevna, Reduta, Kutuzov, Kozák, Mušketýr.
    `A: French blue, white and red with gold eagles; bicorne hats, bearskin caps, epaulettes | base: blue | rim: gold`
    `B: dark green and white with imperial yellow; shako hats, double-headed eagles, lances | base: imperial yellow | rim: white`

### 2.C Fantasy

21. **Rytíři × Orkové** 🟢 — Král v plné zbroji, Královna-válečnice, Hradní bašta, Klerik s palcátem, Rytíř na obrněném koni, Zbrojnoš. Náčelník s kostěnou korunou, Šamanka, Jeskynní troll s balvanem, Šaman s lebkovou holí, Kančí jezdec, Goblin se šavlí.
    `A: royal blue, silver and gold; plate armor, lion heraldry, banners | base: royal blue | rim: silver`
    `B: olive green skin, rust orange and bone; spiked scrap armor, tusks, war paint | base: rust orange | rim: sickly yellow`
22. **Elfové × Skřeti** 🟢 — Král lesa s parožím, Paní hvězd, Stromový strážce, Lukostřelkyně, Jezdec na jelenu, Hraničář. Skřetí král na trůnu z haraburdí, Bažinná ježibaba, Katapult ze šrotu, Alchymista, Jezdec na obří kryse, Skřetík s pokličkou.
    `A: leaf green, silver and moonlight white; flowing cloaks, vines, antlers, crystal | base: leaf green | rim: silver`
    `B: mustard yellow, grubby purple and scrap metal; patched leather, pots as helmets, mushrooms | base: purple | rim: mustard`
23. **Živí × Nemrtví** 🟢 — Paladin-král, Kněžka slunce, Zvonice, Lovec nemrtvých, Paladin na bílém koni, Vesničan s pochodní. Lich, Banshee, Mauzoleum, Nekromant, Kostlivý jezdec, Kostlivec.
    `A: sun yellow, white and red; tabards, torches, sun emblems | base: sun yellow | rim: warm white`
    `B: bone white and teal with ghostly cyan glow; tattered shrouds, rust, cobwebs | base: teal | rim: cyan`
24. **Trpaslíci × Draci** 🟢 — Horský král, Runová královna, Kamenná brána, Runový kovář, Jezdec na kozorožci, Horník. Starý rudý drak, Dračí matka, Kamenný drak stočený do věže, Koboldí šaman, Wyverna, Dráče.
    `A: copper, deep blue and gold; braided beards, runes, heavy geometric armor, gems | base: deep blue | rim: copper`
    `B: ruby red scales with gold belly and amber eyes; horns, wings, smoke, treasure | base: ruby | rim: amber`
25. **Upíři × Vlkodlaci** 🟢 — Hrabě, Hraběnka, Gotický hrad, Komorník se svícnem, Obří netopýr, Upíří páže. Alfa, Měsíční vlčice, Prastarý dub, Šamanka s jelení lebkou, Vlk ve skoku, Vlče.
    `A: wine red, pale skin and antique gold; high collars, capes, bat motifs, candlelight | base: wine red | rim: candle gold`
    `B: silver-grey fur, forest green and moonlight blue; claws, torn cloth, moon charms | base: moonlight blue | rim: silver`

### 2.D Pohádkové a dětské

26. **Pohádkové království × Čerti** 🟢 — Dobrotivý král se zlatým jablkem, Princezna se zlatou hvězdou, Zámecká věž, Kouzelný dědeček, Bílý kůň se zlatou hřívou, Honza s uzlíčkem. Lucifer s knihou hříchů, Čertova babička, Pekelný kotel, Čert-písař, Kozel, Čertík.
    `A: sky blue, white and gold with red hearts; fairy-tale costumes, embroidered folk patterns | base: sky blue | rim: gold`
    `B: sooty brown fur with red tongues and orange fire; little horns, hooves, chains, pitchforks | base: orange | rim: fire yellow`
27. **Víly × Čarodějnice** 🟢 — Král skřítků, Královna víl, Muchomůrkový domeček, Světluška, Jednorožec, Skřítek. Zlý čaroděj, Královna čarodějnic na koštěti, Perníková chaloupka, Vědma s kotlíkem, Černý kocour, Ropucha v kloboučku.
    `A: pink, mint and gold glitter; petals, dragonfly wings, dewdrops | base: mint | rim: pink gold`
    `B: purple, pumpkin orange and slime green; pointed hats, patched cloaks, cobwebs | base: purple | rim: orange`
28. **Louskáček × Myší král** 🟢 — Louskáček, Cukrová víla, Pevnůstka z kostek, Cínový bubeník, Houpací koník, Cínový vojáček. Sedmihlavý Myší král, Myšilda, Pevnost z ementálu, Myší dělostřelec, Krysí oř, Myší vojáček.
    `A: glossy red, white and gold painted wood; tin soldier uniforms, candy canes | base: red | rim: gold`
    `B: grey fur with royal purple capes and cheese yellow; tiny crowns, needles as swords | base: cheese yellow | rim: purple`
29. **Včely × Sršni** 🟢 (obě strany nesmí být žluto-černé) — Včelí král, Včelí královna, Úl, Strážkyně, Čmelák, Dělnice. Sršní král, Vosí královna, Papírové hnízdo, Vosa-lučištnice, Vážka, Vosí voják.
    `A: honey yellow and warm brown; fuzzy and round, honeycomb hexagons, tiny crowns | base: honey yellow | rim: warm white`
    `B: red-orange and dark maroon with turquoise wings; sharp and angular, paper-nest texture | base: turquoise | rim: red-orange`
30. **Kočky × Psi** 🟢 — Kocour-král, Siamská královna, Škrabadlo, Sphynx-mudrc, Kočka na vysavači, Kotě. Bernardýn, Afghánská chrtice, Psí bouda, Chrt-posel, Jack Russell, Štěně.
    `A: lilac and cream with pink noses; yarn balls, bells, whiskers | base: lilac | rim: pink`
    `B: tan and sky blue with red collars; bones, tennis balls, floppy ears | base: sky blue | rim: warm white`
31. **Dinosauři × Doba ledová** 🟢 — Tyrannosaurus, Pteranodon, Triceratops, Brachiosaurus, Velociraptor, Mládě z vejce. Mamut, Velejelen, Srstnatý nosorožec, Obří lenochod, Šavlozubý tygr, Mamutí mládě.
    `A: jungle green and orange with yellow stripes; scales, ferns, volcano glow | base: orange | rim: yellow`
    `B: shaggy brown fur, ice blue and white; tusks, snow, icicles | base: ice blue | rim: white`
32. **Ovoce × Zelenina** 🟢 — Ananas, Granátové jablko, Meloun, Banán, Kiwi, Borůvka. Brokolice, Kukuřice, Dýně, Mrkev, Chilli, Hrášek.
    `A: tropical yellow, pink and orange; glossy juicy skin, leaf crowns | base: yellow | rim: pink`
    `B: leafy green and purple with earthy brown; matte skin, leaf capes, soil crumbs | base: purple | rim: lime`

### 2.E Sci-fi, živly a věda

33. **Roboti × Mimozemšťané** 🟢 — `A: white and orange plastic with blue LED eyes; rounded panels, antennas, rivets | base: orange | rim: blue` / `B: lime green and magenta with glowing slime; big eyes, tentacles, glass domes | base: magenta | rim: lime`
34. **Oheň × Led** 🟢 — `A: orange, red and yellow flames on dark basalt; embers, lava cracks | base: orange | rim: yellow` / `B: ice blue, white and violet shadows; translucent crystal, frost patterns, snowflakes | base: ice blue | rim: white`
35. **Slunce × Měsíc** 🟢 — `A: gold, orange and sky blue; sun rays, sunflowers, warm glow | base: orange | rim: gold` / `B: indigo and silver with glowing pale yellow stars; crescent shapes, constellations | base: indigo | rim: silver`
36. **Imunita × Bacily** 🟢 — `A: white and light blue with red accents; soft rounded cells, friendly faces, tiny shields | base: light blue | rim: white` / `B: magenta, lime and purple; spiky and slimy, mischievous faces | base: magenta | rim: lime`
37. **Pára × Elektřina** 🟢 — `A: brass, copper and oxblood leather; gears, rivets, pipes, steam puffs, goggles | base: copper | rim: warm amber` / `B: electric cyan and white with chrome; glass tubes, coils, crackling arcs | base: cyan | rim: white blue`

Úplné sestavy figurek všech 37 párů jsou v původním zadání od Olina (zpráva v Claude Code session z 15. 11. 2026); výše je jejich zkrácený přepis.

## 3. Zásobník dalších dvojic

Mýty (Tuatha Dé Danann × Fomoriané, Opeřený had × Kouřící zrcadlo, Nebeský dvůr × démoni, Hrdinové × monstra, Trója × Achájci, Gilgameš × Humbaba), historie (Sparta × Athény, Alexandr × Póros, Řím × Galové, Řím × Germáni, Byzanc × Osmani 🟡, Křižáci × Saladin 🟡, Angličané × Francouzi, Bílá × Červená růže, Samurajové × Ninjové, Tři království, Dívčí válka, Přemysl Otakar × Rudolf, Švédové × studenti 1648, Mušketýři × garda, Robin Hood × šerif, Aztékové × conquistadoři 🟡, Zuluové × Britové 🟡, Šerifové × Psanci, Gladiátoři × šelmy), fantasy (Paladinové × Nekromanti, Lovci × Monstra, Atlantida × Kraken, Řád × Chaos, Golem × přízraky Prahy, Vodníci × Hejkalové, Jednorožci × Draci, Princezny × Draci), zvířata (Kočky × Myši, Lišky × Slepice, Savana × Džungle, Delfíni × Žraloci, Útes × Hlubina, Tučňáci × Medvědi, Žáby × Čápi, Mravenci × Termiti, Berušky × Mšice), hravé (Sladké × Slané, Plyšáci × Roboti, Pastelky × Gumy, Halloween × Vánoce, Trpaslíci × Krtci, Rock × Klasika, Astronauti × Mimozemšťané, Lidé × Stroje, Piráti × Ninjové, Pixely × Neon, Srdcová × Bílá královna), materiálové (Zlato × Stříbro, Křišťál × Obsidián, Jantar × Nefrit, Mramor × Bronz, Porcelán × Terakota, Modré × Rubínové sklo).

**Doporučená první dávka:** `KIDS` 26, 27, 29, 31, 30, 32; `EPIC` 1, 9, 2, 8, 12, 21.

## 4. flux-dev: nastavení a pravidla promptu

- 1024 × 1024, jedna figurka na obrázek. Sestavový náhled 1536 × 1024.
- 24–28 kroků, euler + simple, CFG 1.0, FluxGuidance 3.5; malířštější vzhled 2.5–3.0.
- Negativní prompt se nepoužívá. Co nechceš, popiš kladně.
- Seed pevný pro stranu, 4 kandidáti na figurku (seed, seed+1, …).
- Přirozené anglické věty, podmět na začátku, žádné tagy ani váhy, nikdy „white background“ (místo toho `plain seamless light grey studio backdrop`), SUBJECT 10–30 slov, celý prompt do cca 120 slov, bloky STYLE/DNA/FRAME doslova, žádný text v obrázku, žádná jména žijících autorů, studií ani značek; mytologické postavy podle mýtu.

## 5. Šablona promptu

`{STYLE} {SUBJECT}. {SIL_*} {DNA paleta a motivy}. {FRAME}` — presety, rám, sestavový náhled a hotové SUBJECT věty pro páry 1, 9 a 26 jsou v `tools/faction_art/styles.yaml` a `factions.yaml`.

## 6. Postup

- **Fáze 0 (PoC):** zjistit, jak appka načítá figurky; napojit ComfyUI; sestavový náhled Nebe × Peklo a doladit STYLE a guidance; 12 figurek × 4 kandidáti, výběr; postprocess, archy, akceptační testy. **Stop: ukázat archy ke schválení.**
- **Fáze 1:** `factions.yaml`, `styles.yaml`, `gen_pieces`, `postprocess` (pozadí → ořez → škálování podle výšek → zarovnání dolů → podstavec a obrys → export 512/256/128), `sheets` (siluety, deska, šedotón, barvoslepost).
- **Fáze 2:** SUBJECT věty pro první dávku, pár po páru s kontrolou; vadné figurky přegenerovat s upraveným SUBJECT, ne STYLE.
- **Fáze 3:** skin pack = 12 assetů + `manifest.json`, výběr v nastavení s náhledem, přepínač klasických značek, zrcadlení soupeře.

## 7. Rizika a otevřené otázky

- **Licence:** FLUX.1 [dev] je nekomerční model; před vydáním v placené appce ověřit podmínky pro výstupy, záloha je finál ve schnell. Na L40S smí FLUX-dev zatím jen na interní hodnocení.
- **Citlivé páry (🟡):** bez nálepek dobro × zlo, bez karikatur, v dětské appce ne bez rozmyšlení.
- **Cizí značky:** jen obecné archetypy.
- **K rozhodnutí:** která appka jde první (určuje STYLE), které páry do první dávky, zda podstavec kreslit programově.

## 8. Zdroje k promptování

- [Oficiální FLUX Prompting Guide (Black Forest Labs)](https://docs.us.bfl.ai/guides/prompting_summary)
- [getimg.ai: FLUX.1 Prompt Guide](https://getimg.ai/blog/flux-1-prompt-guide-pro-tips-and-common-mistakes-to-avoid)
- [fal.ai: How to use FLUX](https://fal.ai/learn/tools/how-to-use-flux)
- [Segmind: FLUX Prompting Guide](https://blog.segmind.com/flux-prompting-guide-image-creation/)
