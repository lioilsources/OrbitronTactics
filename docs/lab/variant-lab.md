# Laboratoř variant desky (plán 12, krok 1C)

Spuštění: `dart run tools/variant_lab.dart 200` (Medium proti Medium, 200 her na
variantu, limit 300 tahů, asi 37 s). „Bílý vyhrál“ počítá jen dohrané hry, poslední
čtyři sloupce jsou podíly ze všech her.

| varianta | polí | armáda | bílý vyhrál | tahů | braní | pole moci | oba královští | infiltrace | nedohráno |
|---|---|---|---|---|---|---|---|---|---|
| classic8 | 64 | 16 | 47 % ze 194 | 38,5 | 8,6 | 3 % | 94 % | 1 % | 3 % |
| skirmish6 | 36 | 12 | 57 % z 200 | 10,6 | 4,2 | 29 % | 71 % | 1 % | 0 % |
| tall8x10 | 80 | 16 | 48 % ze 195 | 34,7 | 7,0 | 1 % | 96 % | 2 % | 3 % |
| grand10 | 100 | 16 | 53 % ze 195 | 39,2 | 8,0 | 0 % | 97 % | 1 % | 3 % |
| grand10_20 | 100 | 20 | 52 % ze 195 | 42,4 | 8,9 | 3 % | 95 % | 0 % | 3 % |
| rocks8 | 60 | 16 | 50 % ze 195 | 40,7 | 9,3 | 2 % | 95 % | 2 % | 3 % |
| hex8 | 64 | 16 | 54 % z 200 | 17,8 | 6,9 | 2 % | 98 % | 0 % | 0 % |
| hex8_edge_snipe | 64 | 16 | 57 % z 200 | 21,1 | 8,2 | 0 % | 99 % | 2 % | 0 % |

## Co z toho plyne

- Medium skoro vždy vyhrává braním obou královských figur; pole moci rozhodují jen
  na `skirmish6` (29 %).
- Větší deska hru skoro neprodlouží: `tall8x10` i `grand10` trvají jako klasika
  a mají podobně bitev.
- `skirmish6` je krátká hra na mobil (10,6 tahu, 4,2 bitvy), ale bílý má 57 %.
- Hex v0 se rozhodne velmi rychle (18–21 tahů): posuv přes vrchol neblokují dvě pole,
  mezi kterými prochází, takže dáma a střelci projdou řadou pěšců rovnou ke králům.
  Před UI hexu je potřeba změnit pravidla (posuv přes vrchol blokovat, je-li obsazené
  aspoň jedno z obou polí, nebo zkrátit dosahy).
