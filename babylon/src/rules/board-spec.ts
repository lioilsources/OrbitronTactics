// Port of lib/core/game_logic/board/board_spec.dart: the two boards the web plays first
// (classic8, hex6). The other lab variants come with F1.
import { type BoardGeometry, HexGeometry, SquareGeometry } from './board-geometry';
import { type PieceType, type Position, pos } from './piece';

const r: PieceType = 'rook';
const n: PieceType = 'knight';
const b: PieceType = 'bishop';
const q: PieceType = 'queen';
const k: PieceType = 'king';
const p: PieceType = 'pawn';

export interface BoardSpec {
  readonly id: string;
  readonly geometry: BoardGeometry;
  /** Default formation from the back rank forward, columns left to right as white sees them. */
  readonly layout: readonly (readonly (PieceType | null)[])[];
  readonly powerFieldCount: number;
  /** Fixed power-field variants; null = generated point-symmetric per game. */
  readonly powerFieldVariants: readonly (readonly Position[])[] | null;
}

/** PowerFieldGenerator.variants (power_field_generator.dart), kept as they are. */
export const CLASSIC_VARIANTS: readonly (readonly Position[])[] = [
  [pos(3, 3), pos(3, 4), pos(4, 3), pos(4, 4), pos(3, 5)],
  [pos(2, 3), pos(3, 2), pos(3, 5), pos(4, 4), pos(5, 4)],
  [pos(1, 1), pos(2, 2), pos(5, 5), pos(6, 6), pos(3, 4)],
  [pos(2, 0), pos(2, 7), pos(5, 0), pos(5, 7), pos(3, 4)],
  [pos(2, 3), pos(2, 4), pos(5, 3), pos(5, 4), pos(4, 3)],
  [pos(1, 2), pos(1, 5), pos(6, 2), pos(6, 5), pos(4, 3)],
  [pos(1, 3), pos(3, 1), pos(4, 6), pos(6, 4), pos(3, 4)],
  [pos(1, 4), pos(3, 3), pos(4, 4), pos(6, 3), pos(4, 3)],
];

export const classic8: BoardSpec = {
  id: 'classic8',
  geometry: new SquareGeometry(8, 8),
  layout: [
    [r, n, b, q, k, b, n, r],
    [p, p, p, p, p, p, p, p],
  ],
  powerFieldCount: 5,
  powerFieldVariants: CLASSIC_VARIANTS,
};

export const hex6: BoardSpec = {
  id: 'hex6',
  geometry: HexGeometry.hexagon(6),
  layout: [
    [null, null, null, r, b, q, k, b, r, null, null],
    [null, null, n, null, null, null, null, null, n, null, null],
    [null, null, p, p, p, p, p, p, p, p, null],
  ],
  powerFieldCount: 5,
  powerFieldVariants: null,
};

export const SPECS: readonly BoardSpec[] = [classic8, hex6];

/** The spec called id; throws for an unknown one (BoardSpec.byId). */
export function specById(id: string): BoardSpec {
  const s = SPECS.find((x) => x.id === id);
  if (!s) throw new Error(`Unknown board spec: ${id}`);
  return s;
}

/** How many pieces of each type an army has. */
export function armyOf(spec: BoardSpec): Record<PieceType, number> {
  const counts: Record<PieceType, number> = { pawn: 0, rook: 0, knight: 0, bishop: 0, queen: 0, king: 0 };
  for (const row of spec.layout) for (const t of row) if (t) counts[t]++;
  return counts;
}
