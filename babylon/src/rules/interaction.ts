// Port of the selection half of GameBoard._handleTap / _tapTargets (game_board.dart) and
// BoardInteractionState (board_interaction_provider.dart). Moves arrive with the move rules in F1:
// until then `legalMoves` returns nothing and a tap only selects, switches or deselects.
import { type BoardState, pieceAt } from './board-state';
import { type PlayerColor, type Position, samePos } from './piece';

export interface Interaction {
  readonly selected: Position | null;
  readonly validMoves: readonly Position[];
}

export const NO_SELECTION: Interaction = { selected: null, validMoves: [] };

export type LegalMoves = (from: Position) => readonly Position[];

export type TapOutcome =
  | { kind: 'select'; interaction: Interaction }
  | { kind: 'clear'; interaction: Interaction }
  | { kind: 'move'; from: Position; to: Position; interaction: Interaction }
  | { kind: 'none'; interaction: Interaction };

/** Hot-seat: the player on turn selects their own pieces. */
export const canSelect = (board: BoardState, p: Position, turn: PlayerColor): boolean => pieceAt(board, p)?.color === turn;

/**
 * Cells where a tap does something: the selection and its targets, and the own pieces that have a move.
 * `requireMove` false (F0, no move rules yet) counts every own piece.
 */
export function tapTargets(board: BoardState, it: Interaction, turn: PlayerColor, legalMoves: LegalMoves, requireMove: boolean): Position[] {
  const out: Position[] = [];
  if (it.selected) out.push(it.selected, ...it.validMoves);
  for (const c of board.spec.geometry.cells) {
    if (canSelect(board, c, turn) && (!requireMove || legalMoves(c).length > 0)) out.push(c);
  }
  return out;
}

export function handleTap(board: BoardState, it: Interaction, tapped: Position, turn: PlayerColor, legalMoves: LegalMoves): TapOutcome {
  if (it.selected) {
    if (samePos(it.selected, tapped)) return { kind: 'clear', interaction: NO_SELECTION };
    if (it.validMoves.some((m) => samePos(m, tapped))) {
      return { kind: 'move', from: it.selected, to: tapped, interaction: NO_SELECTION };
    }
    if (canSelect(board, tapped, turn)) {
      return { kind: 'select', interaction: { selected: tapped, validMoves: legalMoves(tapped) } };
    }
    return { kind: 'clear', interaction: NO_SELECTION };
  }
  if (canSelect(board, tapped, turn)) {
    return { kind: 'select', interaction: { selected: tapped, validMoves: legalMoves(tapped) } };
  }
  return { kind: 'none', interaction: it };
}
