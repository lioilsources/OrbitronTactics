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
| hex8_open (kosočtverec) | 64 | 16 | 54 % z 200 | 17,8 | 6,9 | 2 % | 98 % | 0 % | 0 % |
| hex6 | 91 | 16 | 51 % z 594 | 37,8 | 8,6 | 2 % | 97 % | 0 % | 1 % |
| hex6_either | 91 | 16 | 51 % ze 183 | 101,0 | 13,6 | 7 % | 83 % | 3 % | 9 % |
| hex6_open | 91 | 16 | 50 % z 597 | 32,3 | 8,1 | 1 % | 99 % | 1 % | 1 % |
| hex6_edge_snipe | 91 | 16 | 46 % z 599 | 34,4 | 8,4 | 1 % | 99 % | 0 % | 0 % |

## Co z toho plyne

- Medium skoro vždy vyhrává braním obou královských figur; pole moci rozhodují jen
  na `skirmish6` (29 %).
- Větší deska hru skoro neprodlouží: `tall8x10` i `grand10` trvají jako klasika
  a mají podobně bitev.
- `skirmish6` je krátká hra na mobil (10,6 tahu, 4,2 bitvy), ale bílý má 57 %.
- Hex v0 na kosočtverci 8×8 z hexů (`hex8_open`, už v kódu není) se rozhodl velmi rychle
  (18 tahů): posuv přes vrchol neblokovala dvě pole, mezi kterými prochází, takže dáma
  a střelci prošli řadou pěšců rovnou ke králům.
- Hex je od 22/11/2026 šestiúhelník o straně 6 (91 polí, řady 6 až 11), `hex6`.
  Armáda 16: vzadu věž, střelec, dáma, král, střelec, věž; koně na krajích druhé
  řady; osm pěšců ve třetí. Hexy `hex6*` mají 600 her, `hex6_either` 200.
- Pravidla hexu v1: posuv přes vrchol se zastaví, když jsou obsazená **obě** pole vedle
  vrcholu (`CornerBlock.both`, výchozí `hex6`). Hra trvá 37,8 tahu s 8,6 bitvami, jako
  klasika, bílý vyhrává 51 %.
- Zastavit už při jednom obsazeném poli (`hex6_either`) hru skoro ztrojnásobí (101 tahů,
  13,6 bitvy) a 9 % her nedohraje. Bez blokování (`hex6_open`) je hra kratší (32 tahů).
- Snipe střelce „3 přes hranu šikmo vpřed“ (`hex6_edge_snipe`) nahrává černému (bílý
  46 %). Zůstává snipe o dva vrcholy rovně vpřed.
