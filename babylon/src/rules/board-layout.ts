// Port of lib/features/game/presentation/widgets/board/board_layout.dart and tap_resolver.dart.
// Pure geometry (no dart:ui): where every cell sits in board space, y pointing down as in Flutter.
import { type BoardGeometry, HexGeometry } from './board-geometry';
import type { Position } from './piece';

export interface Point {
  readonly x: number;
  readonly y: number;
}

const dist2 = (a: Point, b: Point): number => (a.x - b.x) ** 2 + (a.y - b.y) ** 2;

export class BoardLayout {
  private constructor(
    readonly geometry: BoardGeometry,
    readonly flipped: boolean,
    /** Size of the whole board. */
    readonly width: number,
    readonly height: number,
    /** Width of one cell: a square's side, a hex's width across its flats. */
    readonly cellSize: number,
    /** Twice the column position of the leftmost hex centre (hex only). */
    private readonly minX2 = 0,
  ) {}

  get isHex(): boolean {
    return this.geometry instanceof HexGeometry;
  }

  /** BoardLayout.fit: the layout of geometry at width. */
  static fit(geometry: BoardGeometry, width: number, flipped = false): BoardLayout {
    if (geometry instanceof HexGeometry) {
      const xs = geometry.cells.map(HexGeometry.x2);
      const minX2 = Math.min(...xs);
      const across = (Math.max(...xs) - minX2) / 2 + 1;
      const cell = width / across;
      const radius = cell / Math.sqrt(3);
      const height = radius * (2 + 1.5 * (geometry.rows - 1));
      return new BoardLayout(geometry, flipped, width, height, cell, minX2);
    }
    const cell = width / geometry.cols;
    return new BoardLayout(geometry, flipped, width, cell * geometry.rows, cell);
  }

  /** BoardLayout.within: the largest layout that fits in the box. */
  static within(geometry: BoardGeometry, boxWidth: number, boxHeight: number, flipped = false): BoardLayout {
    const wide = BoardLayout.fit(geometry, boxWidth, flipped);
    if (!Number.isFinite(boxHeight) || wide.height <= boxHeight) return wide;
    return BoardLayout.fit(geometry, (boxWidth * boxHeight) / wide.height, flipped);
  }

  /** A hex's corner distance from its centre. */
  get radius(): number {
    return this.cellSize / Math.sqrt(3);
  }

  centreOf(p: Position): Point {
    const visualRow = this.geometry.rows - 1 - p.row;
    const u: Point = this.isHex
      ? { x: ((HexGeometry.x2(p) - this.minX2) / 2 + 0.5) * this.cellSize, y: this.radius + visualRow * 1.5 * this.radius }
      : { x: (p.col + 0.5) * this.cellSize, y: (visualRow + 0.5) * this.cellSize };
    return this.flipped ? { x: this.width - u.x, y: this.height - u.y } : u;
  }

  /** The outline of p's cell as a polygon (cellPath). */
  cellPolygon(p: Position, inset = 0): Point[] {
    const c = this.centreOf(p);
    if (!this.isHex) {
      const h = this.cellSize / 2 - inset;
      return [
        { x: c.x - h, y: c.y - h },
        { x: c.x + h, y: c.y - h },
        { x: c.x + h, y: c.y + h },
        { x: c.x - h, y: c.y + h },
      ];
    }
    const r = this.radius - (inset * 2) / Math.sqrt(3);
    const out: Point[] = [];
    for (let i = 0; i < 6; i++) {
      const a = Math.PI / 2 + (i * Math.PI) / 3; // pointy top: corners at ±90°
      out.push({ x: c.x + r * Math.cos(a), y: c.y + r * Math.sin(a) });
    }
    return out;
  }

  /** Which of the two (square) or three (hex) shades p gets; 0 is the lightest. */
  shadeOf(p: Position): number {
    if (!this.isHex) return (this.geometry.rows - 1 - p.row + p.col) % 2;
    const q = p.col - (p.row >> 1);
    // Dart's % is never negative.
    return (((q - p.row) % 3) + 3) % 3;
  }

  /** The cell under point, or null off the board. */
  positionAt(point: Point): Position | null {
    let best: Position | null = null;
    let bestD = Infinity;
    for (const p of this.geometry.cells) {
      const d = dist2(this.centreOf(p), point);
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    const limit = this.isHex ? this.radius : (this.cellSize * Math.SQRT2) / 2;
    return bestD <= limit * limit ? best : null;
  }
}

/** tapReachFor: hex taps snap within 0.8 of a cell, the square board keeps exact taps. */
export const tapReachFor = (layout: BoardLayout): number => (layout.isHex ? 0.8 : 0);

/** resolveTap: the cell a tap at point means, preferring cells where a tap does something. */
export function resolveTap(layout: BoardLayout, point: Point, preferred: readonly Position[], reach = 0.8): Position | null {
  if (reach >= 1) throw new Error('reach must stay below one cell width');
  const exact = layout.positionAt(point);
  const isPreferred = (p: Position): boolean => preferred.some((q) => q.row === p.row && q.col === p.col);
  if (exact && isPreferred(exact)) return exact;
  if (reach <= 0) return exact;
  const limit = reach * layout.cellSize;
  let best: Position | null = null;
  let bestD = limit * limit;
  for (const p of preferred) {
    const d = dist2(layout.centreOf(p), point);
    if (d < bestD || (best === null && d === bestD)) {
      bestD = d;
      best = p;
    }
  }
  return best ?? exact;
}
