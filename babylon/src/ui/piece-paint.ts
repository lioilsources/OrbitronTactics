// Canvas 2D port of PieceRenderer._classicPiece (piece_renderer.dart): a circle with the chess
// symbol, 0.85 of the cell, border and drop shadow; orange glow for a Last Warrior.
// The image packs (assets/pieces/) come in F3.
import type { Piece, PieceType } from '../rules/piece';
import { BOARD_THEME as T } from './generated/board-theme';
import { withAlpha } from './palette';

const SYMBOLS: Record<PieceType, string> = {
  king: '♔',
  queen: '♕',
  rook: '♖',
  bishop: '♗',
  knight: '♘',
  pawn: '♙',
};

/** U+FE0E keeps the text glyph where a platform would draw an emoji. */
export const symbol = (t: PieceType): string => SYMBOLS[t] + '︎';

const GLYPH_FONT = '"Apple Symbols", "Segoe UI Symbol", "Noto Sans Symbols 2", "DejaVu Sans", system-ui, sans-serif';

/**
 * Paints piece into a size × size canvas: the cell box the piece is drawn in.
 * Flutter sizes in logical pixels of a ~44 dp cell; k scales them.
 */
export function paintClassicPiece(ctx: CanvasRenderingContext2D, pc: Piece, size: number): void {
  const k = size / 44;
  const white = pc.color === 'white';
  const r = (size * 0.85) / 2;
  const cx = size / 2;
  const cy = size / 2;
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.clearRect(0, 0, size, size);

  if (pc.isLastWarrior) {
    ctx.save();
    ctx.shadowColor = withAlpha(T.lastWarriorGlow, 0.5);
    ctx.shadowBlur = 8 * k;
    ctx.beginPath();
    ctx.arc(cx, cy, r + 2 * k, 0, Math.PI * 2);
    ctx.fillStyle = withAlpha(T.lastWarriorGlow, 0.5);
    ctx.fill();
    ctx.restore();
  }

  ctx.save();
  ctx.shadowColor = 'rgba(0,0,0,0.3)';
  ctx.shadowBlur = 2 * k;
  ctx.shadowOffsetX = k;
  ctx.shadowOffsetY = k;
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, Math.PI * 2);
  ctx.fillStyle = white ? T.whitePieceColor : T.blackPieceColor;
  ctx.fill();
  ctx.restore();

  const bw = (pc.isLastWarrior ? 2.5 : 1.5) * k;
  ctx.beginPath();
  ctx.arc(cx, cy, r - bw / 2, 0, Math.PI * 2);
  ctx.strokeStyle = pc.isLastWarrior ? T.lastWarriorGlow : white ? T.whitePieceBorder : T.blackPieceBorder;
  ctx.lineWidth = bw;
  ctx.stroke();

  ctx.fillStyle = white ? 'rgba(0,0,0,0.87)' : '#FFFFFF';
  ctx.font = `${Math.round(size * 0.5)}px ${GLYPH_FONT}`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  const m = ctx.measureText(symbol(pc.type));
  // Centre the ink, not the em box: symbol fonts sit their glyphs at different heights.
  const dy = (m.actualBoundingBoxAscent - m.actualBoundingBoxDescent) / 2;
  ctx.textBaseline = 'alphabetic';
  ctx.fillText(symbol(pc.type), cx, cy + dy);
}
