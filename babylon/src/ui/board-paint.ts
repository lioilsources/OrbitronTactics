// Canvas 2D port of BoardBackgroundPainter (board_background_painter.dart) and BoardOverlayPainter
// (board_overlay_painter.dart). Split into layers so game/ can pulse the power-field fill
// (Flutter's glowOpacity) by material alpha instead of repainting every frame:
//   cells  → fill (opaque colours, alpha animated) → overlay (field borders, diamonds, selection).
// Coordinates are board units (BoardLayout); `scale` is texture pixels per unit.
import type { BoardLayout, Point } from '../rules/board-layout';
import { type BoardState, pieceAt } from '../rules/board-state';
import type { Interaction } from '../rules/interaction';
import type { Position } from '../rules/piece';
import { BOARD_THEME as T } from './generated/board-theme';
import { lerpCss, opaque, withAlpha } from './palette';

type Ctx = CanvasRenderingContext2D;

function polygon(ctx: Ctx, pts: readonly Point[]): void {
  ctx.beginPath();
  pts.forEach((p, i) => (i === 0 ? ctx.moveTo(p.x, p.y) : ctx.lineTo(p.x, p.y)));
  ctx.closePath();
}

function begin(ctx: Ctx, scale: number): void {
  ctx.setTransform(1, 0, 0, 1, 0, 0);
  ctx.clearRect(0, 0, ctx.canvas.width, ctx.canvas.height);
  ctx.setTransform(scale, 0, 0, scale, 0, 0);
}

/** The fill and border colours of a power field, by the piece standing on it. */
export function fieldColors(board: BoardState, p: Position): { fill: string; border: string } {
  const pc = pieceAt(board, p);
  if (pc?.color === 'white') return { fill: T.powerFieldWhiteOwned, border: T.powerFieldWhiteBorder };
  if (pc?.color === 'black') return { fill: T.powerFieldBlackOwned, border: T.powerFieldBlackBorder };
  return { fill: T.powerFieldColor, border: T.powerFieldBorder };
}

export interface SquareColors {
  light: string;
  dark: string;
}

export const CLASSIC_SQUARES: SquareColors = { light: T.lightSquare, dark: T.darkSquare };

export function paintCells(ctx: Ctx, layout: BoardLayout, board: BoardState, scale: number, sq: SquareColors = CLASSIC_SQUARES): void {
  begin(ctx, scale);
  const shades = layout.isHex ? [sq.light, lerpCss(sq.light, sq.dark, 0.5), sq.dark] : [sq.light, sq.dark];
  for (const cell of board.spec.geometry.cells) {
    polygon(ctx, layout.cellPolygon(cell));
    ctx.fillStyle = shades[layout.shadeOf(cell)];
    ctx.fill();
    // Hairline in the cell's own colour closes the anti-aliasing seams between neighbours.
    ctx.strokeStyle = ctx.fillStyle;
    ctx.lineWidth = 1 / scale;
    ctx.stroke();
  }
}

/** Power-field fills at full opacity: Flutter replaces their alpha with glowOpacity. */
export function paintFieldFills(ctx: Ctx, layout: BoardLayout, board: BoardState, scale: number): void {
  begin(ctx, scale);
  for (const pf of board.powerFields) {
    polygon(ctx, layout.cellPolygon(pf));
    ctx.fillStyle = opaque(fieldColors(board, pf).fill);
    ctx.fill();
  }
}

/** One logical pixel of the Flutter board, in board units (a phone cell is about 44 dp). */
const dp = (layout: BoardLayout): number => layout.cellSize / 44;

export function paintOverlay(ctx: Ctx, layout: BoardLayout, board: BoardState, it: Interaction, scale: number): void {
  begin(ctx, scale);
  const px = dp(layout);
  for (const pf of board.powerFields) {
    const { border } = fieldColors(board, pf);
    polygon(ctx, layout.cellPolygon(pf, px));
    ctx.strokeStyle = border;
    ctx.lineWidth = 2 * px;
    ctx.stroke();
    const c = layout.centreOf(pf);
    const d = layout.cellSize * 0.15;
    polygon(ctx, [{ x: c.x, y: c.y - d }, { x: c.x + d, y: c.y }, { x: c.x, y: c.y + d }, { x: c.x - d, y: c.y }]);
    ctx.fillStyle = withAlpha(border, 0.5);
    ctx.fill();
  }

  if (it.selected) {
    polygon(ctx, layout.cellPolygon(it.selected));
    ctx.fillStyle = T.selectedSquare;
    ctx.fill();
  }
  for (const m of it.validMoves) {
    if (pieceAt(board, m)) {
      paintCaptureIndicator(ctx, layout, m, px);
    } else {
      const c = layout.centreOf(m);
      ctx.beginPath();
      ctx.arc(c.x, c.y, layout.cellSize * 0.15, 0, Math.PI * 2);
      ctx.fillStyle = T.validMoveIndicator;
      ctx.fill();
    }
  }
}

function paintCaptureIndicator(ctx: Ctx, layout: BoardLayout, p: Position, px: number): void {
  ctx.strokeStyle = T.captureIndicator;
  ctx.lineWidth = 3 * px;
  if (layout.isHex) {
    polygon(ctx, layout.cellPolygon(p, layout.cellSize * 0.06));
    ctx.stroke();
    return;
  }
  const c = layout.centreOf(p);
  const h = layout.cellSize / 2 - layout.cellSize * 0.05;
  const k = layout.cellSize * 0.25;
  ctx.beginPath();
  for (const [sx, sy] of [[-1, -1], [1, -1], [-1, 1], [1, 1]] as const) {
    const x = c.x + sx * h;
    const y = c.y + sy * h;
    ctx.moveTo(x - sx * k, y);
    ctx.lineTo(x, y);
    ctx.lineTo(x, y - sy * k);
  }
  ctx.stroke();
}
