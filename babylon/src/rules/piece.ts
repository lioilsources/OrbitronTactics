// Port of lib/core/game_logic/models/piece.dart and position.dart.

export const PIECE_TYPES = ['pawn', 'rook', 'knight', 'bishop', 'queen', 'king'] as const;
export type PieceType = (typeof PIECE_TYPES)[number];

export type PlayerColor = 'white' | 'black';

export const opposite = (c: PlayerColor): PlayerColor => (c === 'white' ? 'black' : 'white');

export interface Piece {
  readonly type: PieceType;
  readonly color: PlayerColor;
  readonly isLastWarrior: boolean;
}

export const piece = (type: PieceType, color: PlayerColor, isLastWarrior = false): Piece => ({ type, color, isLastWarrior });

export const isRoyal = (p: Piece): boolean => p.type === 'king' || p.type === 'queen';

/** row 0 = white's back rank, col 0 = left from white's side. */
export interface Position {
  readonly row: number;
  readonly col: number;
}

export const pos = (row: number, col: number): Position => ({ row, col });

export const samePos = (a: Position | null | undefined, b: Position | null | undefined): boolean =>
  a != null && b != null && a.row === b.row && a.col === b.col;

/** Stable key for sets and maps (Dart's value equality). */
export const posKey = (p: Position): string => `${p.row},${p.col}`;
