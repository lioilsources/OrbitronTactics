// Port of lib/core/game_logic/models/board_state.dart, GameEngine.defaultFormation (game_engine.dart)
// and the variant / symmetric parts of PowerFieldGenerator (power_field_generator.dart).
import type { BoardGeometry } from './board-geometry';
import type { BoardSpec } from './board-spec';
import { type Piece, type PlayerColor, type Position, piece, pos } from './piece';

export interface BoardState {
  /** rows × cols, grid[row][col]; null = empty. */
  readonly grid: readonly (readonly (Piece | null)[])[];
  readonly powerFields: readonly Position[];
  readonly spec: BoardSpec;
}

export const geometryOf = (b: BoardState): BoardGeometry => b.spec.geometry;

export const pieceAt = (b: BoardState, p: Position): Piece | null => b.grid[p.row]?.[p.col] ?? null;

export function emptyBoard(spec: BoardSpec, powerFields: readonly Position[]): BoardState {
  const g = spec.geometry;
  return { grid: Array.from({ length: g.rows }, () => Array.from({ length: g.cols }, () => null)), powerFields, spec };
}

export function setPiece(b: BoardState, p: Position, pc: Piece | null): BoardState {
  const grid = b.grid.map((row) => [...row]);
  grid[p.row][p.col] = pc;
  return { ...b, grid };
}

export function movePiece(b: BoardState, from: Position, to: Position): BoardState {
  const grid = b.grid.map((row) => [...row]);
  grid[to.row][to.col] = grid[from.row][from.col];
  grid[from.row][from.col] = null;
  return { ...b, grid };
}

export interface Placement {
  readonly position: Position;
  readonly piece: Piece;
}

/** GameEngine.defaultFormation: spec's layout on color's rows. */
export function defaultFormation(color: PlayerColor, spec: BoardSpec): Placement[] {
  const out: Placement[] = [];
  spec.layout.forEach((types, i) => {
    const row = color === 'white' ? i : spec.geometry.rows - 1 - i;
    types.forEach((type, col) => {
      if (type) out.push({ position: pos(row, col), piece: piece(type, color) });
    });
  });
  return out;
}

/** Both default formations on an empty board: the board a quick hot-seat game starts from. */
export function startingBoard(spec: BoardSpec, powerFields: readonly Position[]): BoardState {
  let b = emptyBoard(spec, powerFields);
  for (const color of ['white', 'black'] as const) {
    for (const pl of defaultFormation(color, spec)) b = setPiece(b, pl.position, pl.piece);
  }
  return b;
}

/** Source of `nextInt(max)` draws, so the generator can later run on a bit-exact port of Dart's Random. */
export interface IntSource {
  nextInt(max: number): number;
}

/** PowerFieldGenerator.generateFor. */
export function generatePowerFields(spec: BoardSpec, random: IntSource): Position[] {
  const fixed = spec.powerFieldVariants;
  if (fixed) return [...fixed[random.nextInt(fixed.length)]];
  return symmetricFields(spec.geometry, spec.powerFieldCount, random, spec.layout.length);
}

/** PowerFieldGenerator.symmetric: count point-symmetric fields outside the first marginRows rows of either side. */
export function symmetricFields(geometry: BoardGeometry, count: number, random: IntSource, marginRows = 2): Position[] {
  const band = geometry.cells.filter((c) => c.row >= marginRows && c.row < geometry.rows - marginRows);
  const same = (a: Position, b: Position | null): boolean => b !== null && a.row === b.row && a.col === b.col;

  const fields: Position[] = [];
  let centre: Position | null = null;
  if (count % 2 === 1) {
    const nearest = Math.min(...band.map((c) => geometry.distanceFromCentre(c)));
    const candidates = band.filter((c) => geometry.distanceFromCentre(c) - nearest < 1e-9);
    centre = candidates[random.nextInt(candidates.length)];
  }
  const pool = band.filter((cell) => {
    const m = geometry.mirror(cell);
    return geometry.indexOf(cell) < geometry.indexOf(m) && geometry.contains(m) && !same(cell, centre) && !same(m, centre);
  });
  const pairs = Math.floor(count / 2);
  if (pool.length < pairs) throw new Error(`Board too small for ${count} power fields`);
  for (let i = 0; i < pairs; i++) {
    const [cell] = pool.splice(random.nextInt(pool.length), 1);
    fields.push(cell, geometry.mirror(cell));
  }
  if (centre) fields.push(centre);
  return fields;
}

/**
 * Small seeded LCG for the F0 spike (`?seed=`). NOT Dart's Random: F1 replaces it with a
 * bit-exact port so the same seed gives the same power fields as Flutter (see PORT.md, Odchylky).
 */
export function lcg(seed: number): IntSource {
  let s = seed >>> 0 || 1;
  return {
    nextInt(max: number): number {
      s = (Math.imul(s, 1664525) + 1013904223) >>> 0;
      return Math.floor((s / 0x100000000) * max);
    },
  };
}
