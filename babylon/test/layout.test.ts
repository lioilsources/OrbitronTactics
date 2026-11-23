import { describe, expect, it } from 'vitest';
import { BoardLayout, resolveTap, tapReachFor } from '../src/rules/board-layout';
import { classic8, hex6 } from '../src/rules/board-spec';
import { startingBoard } from '../src/rules/board-state';
import { handleTap, NO_SELECTION, tapTargets } from '../src/rules/interaction';
import { pos } from '../src/rules/piece';

// Expected numbers follow board_layout_test.dart / tap_resolver_test.dart in the Flutter project.

describe('BoardLayout', () => {
  it('square: white back row at the bottom, flipped turns it around', () => {
    const l = BoardLayout.fit(classic8.geometry, 400);
    expect(l.cellSize).toBe(50);
    expect(l.height).toBe(400);
    expect(l.centreOf(pos(0, 0))).toEqual({ x: 25, y: 375 });
    const f = BoardLayout.fit(classic8.geometry, 400, true);
    expect(f.centreOf(pos(0, 0))).toEqual({ x: 375, y: 25 });
  });

  it('square: shades alternate, (0,0) dark as in board_layout_test.dart', () => {
    const l = BoardLayout.fit(classic8.geometry, 400);
    expect(l.shadeOf(pos(0, 0))).toBe(1);
    expect(l.shadeOf(pos(0, 1))).toBe(0);
    expect(l.shadeOf(pos(1, 0))).toBe(0);
  });

  it('hex: 11 cells across the long row, height from the row count', () => {
    const l = BoardLayout.fit(hex6.geometry, 110);
    expect(l.cellSize).toBeCloseTo(10, 12);
    const r = 10 / Math.sqrt(3);
    expect(l.height).toBeCloseTo(r * (2 + 1.5 * 10), 9);
    // Long middle row spans the full width.
    expect(l.centreOf(pos(5, 0)).x).toBeCloseTo(5, 9);
    expect(l.centreOf(pos(5, 10)).x).toBeCloseTo(105, 9);
  });

  it('hex: three shades, no two neighbours alike', () => {
    const l = BoardLayout.fit(hex6.geometry, 110);
    const cells = hex6.geometry.cells;
    for (const a of cells) {
      for (const b of cells) {
        const ca = l.centreOf(a);
        const cb = l.centreOf(b);
        const d = Math.hypot(ca.x - cb.x, ca.y - cb.y);
        if (d > 0 && d < l.cellSize * 1.01) expect(l.shadeOf(a)).not.toBe(l.shadeOf(b));
      }
      expect([0, 1, 2]).toContain(l.shadeOf(a));
    }
  });

  it('positionAt finds every cell at its centre and nothing far off the board', () => {
    for (const spec of [classic8, hex6]) {
      const l = BoardLayout.fit(spec.geometry, 300);
      for (const c of spec.geometry.cells) expect(l.positionAt(l.centreOf(c))).toEqual(c);
      expect(l.positionAt({ x: -100, y: -100 })).toBeNull();
    }
  });

  it('within fits the height when the box is wide', () => {
    const l = BoardLayout.within(classic8.geometry, 800, 400);
    expect(l.width).toBe(400);
  });
});

describe('resolveTap', () => {
  it('square keeps exact taps', () => {
    expect(tapReachFor(BoardLayout.fit(classic8.geometry, 400))).toBe(0);
  });

  it('hex snaps a tap off every useful cell to the nearest preferred one within reach', () => {
    const l = BoardLayout.fit(hex6.geometry, 110);
    const target = pos(1, 2);
    const c = l.centreOf(target);
    // Into the empty neighbour to the east, 0.7 cells away.
    const tap = { x: c.x + 0.7 * l.cellSize, y: c.y };
    expect(l.positionAt(tap)).not.toEqual(target);
    expect(resolveTap(l, tap, [target], 0.8)).toEqual(target);
    expect(resolveTap(l, { x: c.x + 0.9 * l.cellSize, y: c.y }, [target], 0.8)).toEqual(l.positionAt({ x: c.x + 0.9 * l.cellSize, y: c.y }));
  });

  it('rejects a reach of a full cell', () => {
    const l = BoardLayout.fit(hex6.geometry, 110);
    expect(() => resolveTap(l, { x: 0, y: 0 }, [], 1)).toThrow();
  });
});

describe('tap selects (hot-seat, F0 without move rules)', () => {
  const board = startingBoard(classic8, []);
  const none = () => [];

  it('selects an own piece, deselects on a second tap, switches to another own piece', () => {
    const a = handleTap(board, NO_SELECTION, pos(0, 4), 'white', none);
    expect(a.kind).toBe('select');
    expect(a.interaction.selected).toEqual(pos(0, 4));
    const b = handleTap(board, a.interaction, pos(1, 3), 'white', none);
    expect(b.interaction.selected).toEqual(pos(1, 3));
    expect(handleTap(board, b.interaction, pos(1, 3), 'white', none).interaction).toEqual(NO_SELECTION);
  });

  it('ignores the opponent and empty cells', () => {
    expect(handleTap(board, NO_SELECTION, pos(7, 4), 'white', none).kind).toBe('none');
    expect(handleTap(board, NO_SELECTION, pos(4, 4), 'white', none).kind).toBe('none');
    expect(handleTap(board, NO_SELECTION, pos(7, 4), 'black', none).kind).toBe('select');
  });

  it('a tap on a valid move target is a move', () => {
    const sel = { selected: pos(1, 4), validMoves: [pos(2, 4)] };
    expect(handleTap(board, sel, pos(2, 4), 'white', none)).toMatchObject({ kind: 'move', from: pos(1, 4), to: pos(2, 4) });
  });

  it('tap targets: own pieces plus the selection and its moves', () => {
    expect(tapTargets(board, NO_SELECTION, 'white', none, false)).toHaveLength(16);
    expect(tapTargets(board, NO_SELECTION, 'white', none, true)).toHaveLength(0);
  });
});
