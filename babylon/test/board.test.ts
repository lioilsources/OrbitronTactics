import { describe, expect, it } from 'vitest';
import { HexGeometry } from '../src/rules/board-geometry';
import { armyOf, classic8, hex6, specById } from '../src/rules/board-spec';
import { defaultFormation, generatePowerFields, lcg, pieceAt, startingBoard, symmetricFields } from '../src/rules/board-state';
import { pos, posKey } from '../src/rules/piece';

describe('board geometry', () => {
  it('classic8 has 64 cells', () => {
    expect(classic8.geometry.cells).toHaveLength(64);
  });

  it('hex6 is a hexagon of 91 cells, rows of 6 to 11', () => {
    const g = hex6.geometry;
    expect(g.cells).toHaveLength(91);
    const perRow = Array.from({ length: g.rows }, (_, r) => g.cells.filter((c) => c.row === r).length);
    expect(perRow).toEqual([6, 7, 8, 9, 10, 11, 10, 9, 8, 7, 6]);
  });

  it('the hex mirror is an involution onto the board', () => {
    const g = hex6.geometry;
    for (const c of g.cells) {
      const m = g.mirror(c);
      expect(g.contains(m)).toBe(true);
      expect(g.mirror(m)).toEqual(c);
      expect(g.distanceFromCentre(m)).toBeCloseTo(g.distanceFromCentre(c), 12);
    }
  });

  it('the hex centre is the middle of the long row', () => {
    expect((hex6.geometry as HexGeometry).distanceFromCentre(pos(5, 5))).toBe(0);
  });

  it('specById rejects unknown ids', () => {
    expect(specById('hex6')).toBe(hex6);
    expect(() => specById('nope')).toThrow();
  });
});

describe('starting board', () => {
  it('classic: 16 pieces a side in chess order, black mirrored by rows', () => {
    const b = startingBoard(classic8, []);
    expect(defaultFormation('white', classic8)).toHaveLength(16);
    expect(pieceAt(b, pos(0, 4))).toEqual({ type: 'king', color: 'white', isLastWarrior: false });
    expect(pieceAt(b, pos(7, 3))).toEqual({ type: 'queen', color: 'black', isLastWarrior: false });
    expect(pieceAt(b, pos(6, 0))?.type).toBe('pawn');
    expect(pieceAt(b, pos(3, 3))).toBeNull();
  });

  it('hex6: every placed piece stands on a board cell', () => {
    expect(armyOf(hex6)).toEqual({ pawn: 8, rook: 2, knight: 2, bishop: 2, queen: 1, king: 1 });
    for (const color of ['white', 'black'] as const) {
      for (const pl of defaultFormation(color, hex6)) expect(hex6.geometry.contains(pl.position)).toBe(true);
    }
  });
});

describe('power fields', () => {
  it('classic picks one of the 8 fixed variants', () => {
    const f = generatePowerFields(classic8, { nextInt: (max) => (expect(max).toBe(8), 2) });
    expect(f.map(posKey)).toEqual(['1,1', '2,2', '5,5', '6,6', '3,4']);
  });

  it('hex6: five point-symmetric fields outside the formation rows, one at the centre', () => {
    for (let seed = 1; seed < 50; seed++) {
      const f = symmetricFields(hex6.geometry, 5, lcg(seed), hex6.layout.length);
      expect(new Set(f.map(posKey)).size).toBe(5);
      expect(f[4]).toEqual(pos(5, 5));
      for (const p of f) {
        expect(p.row).toBeGreaterThanOrEqual(3);
        expect(p.row).toBeLessThanOrEqual(7);
      }
      expect(f[1]).toEqual(hex6.geometry.mirror(f[0]));
      expect(f[3]).toEqual(hex6.geometry.mirror(f[2]));
    }
  });
});
