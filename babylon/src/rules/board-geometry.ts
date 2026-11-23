// Port of the cell-shape part of lib/core/game_logic/board/board_geometry.dart:
// which cells exist, the point mirror and the distance from the centre.
// Directions, reach, knight jumps and snipes come with the move rules in F1.
import { type Position, pos } from './piece';

export type CornerBlock = 'open' | 'both' | 'either';
export type HexSnipe = 'vertexForward' | 'edgeDiagonal';

export abstract class BoardGeometry {
  constructor(
    readonly rows: number,
    readonly cols: number,
    /** Squares that are not part of the board (rocks). */
    readonly blocked: readonly Position[] = [],
  ) {}

  get cellCount(): number {
    return this.rows * this.cols;
  }

  /** Whether p is on the board and not blocked. */
  contains(p: Position): boolean {
    if (p.row < 0 || p.row >= this.rows || p.col < 0 || p.col >= this.cols) return false;
    for (const b of this.blocked) if (b.row === p.row && b.col === p.col) return false;
    return true;
  }

  /** Point-symmetric mirror about the board's centre. */
  mirror(p: Position): Position {
    return pos(this.rows - 1 - p.row, this.cols - 1 - p.col);
  }

  /** A dense index of p, for the AI's bit sets. */
  indexOf(p: Position): number {
    return p.row * this.cols + p.col;
  }

  /** Distance of p's centre from the board's centre, in cell widths. */
  abstract distanceFromCentre(p: Position): number;

  /** Every cell of the board, row by row (Dart's `cells`). */
  get cells(): Position[] {
    const out: Position[] = [];
    for (let row = 0; row < this.rows; row++) {
      for (let col = 0; col < this.cols; col++) {
        const p = pos(row, col);
        if (this.contains(p)) out.push(p);
      }
    }
    return out;
  }

  backRank(white: boolean): number {
    return white ? 0 : this.rows - 1;
  }
}

/** The classic square board. */
export class SquareGeometry extends BoardGeometry {
  distanceFromCentre(p: Position): number {
    const dy = p.row - (this.rows - 1) / 2;
    const dx = p.col - (this.cols - 1) / 2;
    return Math.sqrt(dx * dx + dy * dy);
  }
}

/**
 * Pointy-top hexes in horizontal rows, offset coordinates with odd rows shifted half a cell right.
 * With a `side` the board is a hexagon of that many cells a side cut out of a (2·side − 1)² grid.
 */
export class HexGeometry extends BoardGeometry {
  constructor(
    rows: number,
    cols: number,
    readonly side: number | null = null,
    readonly cornerBlock: CornerBlock = 'both',
    readonly snipe: HexSnipe = 'vertexForward',
    blocked: readonly Position[] = [],
  ) {
    super(rows, cols, blocked);
  }

  /** A hexagon with `side` cells along each edge. */
  static hexagon(side: number, cornerBlock: CornerBlock = 'both', snipe: HexSnipe = 'vertexForward'): HexGeometry {
    return new HexGeometry(2 * side - 1, 2 * side - 1, side, cornerBlock, snipe);
  }

  /** Twice the column position of a cell's centre, odd rows' half shift included. */
  static x2(p: Position): number {
    return 2 * p.col + (p.row & 1);
  }

  private get centreX2(): number {
    return this.side !== null ? 2 * this.side - 1 : this.cols - 0.5;
  }

  override contains(p: Position): boolean {
    if (!super.contains(p)) return false;
    const s = this.side;
    if (s === null) return true;
    const dRow = Math.abs(p.row - (s - 1));
    return Math.abs(HexGeometry.x2(p) - (2 * s - 1)) <= 2 * (s - 1) - dRow;
  }

  override mirror(p: Position): Position {
    if (this.side === null) return super.mirror(p);
    const row = this.rows - 1 - p.row;
    // Dart's ~/ truncates; the numerator is never negative here.
    return pos(row, Math.trunc((2 * (2 * this.side - 1) - HexGeometry.x2(p) - (row & 1)) / 2));
  }

  distanceFromCentre(p: Position): number {
    const dx = (HexGeometry.x2(p) - this.centreX2) / 2;
    const dy = ((p.row - (this.rows - 1) / 2) * Math.sqrt(3)) / 2;
    return Math.sqrt(dx * dx + dy * dy);
  }
}
