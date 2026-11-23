// Colour helpers over the generated BoardTheme (generated/board-theme.ts, from board_theme.dart).

export { BOARD_THEME } from './generated/board-theme';

/** Scaffold background of GameScreen (game_screen.dart, `Color(0xFF1A1A2E)` inline in the widget). */
export const SCREEN_BG = '#1A1A2E';

type Rgba = [number, number, number, number];

export function parseCss(css: string): Rgba {
  const hex = /^#([0-9a-f]{6})$/i.exec(css);
  if (hex) {
    const v = parseInt(hex[1], 16);
    return [(v >> 16) & 0xff, (v >> 8) & 0xff, v & 0xff, 1];
  }
  const m = /^rgba\((\d+),(\d+),(\d+),([\d.]+)\)$/.exec(css);
  if (m) return [+m[1], +m[2], +m[3], +m[4]];
  throw new Error(`Unsupported colour: ${css}`);
}

const toCss = ([r, g, b, a]: Rgba): string => `rgba(${Math.round(r)},${Math.round(g)},${Math.round(b)},${+a.toFixed(4)})`;

/** Color.withValues(alpha:): same RGB, alpha replaced. */
export const withAlpha = (css: string, alpha: number): string => {
  const [r, g, b] = parseCss(css);
  return toCss([r, g, b, alpha]);
};

export const opaque = (css: string): string => withAlpha(css, 1);

/** Color.lerp. */
export function lerpCss(a: string, b: string, t: number): string {
  const x = parseCss(a);
  const y = parseCss(b);
  return toCss([0, 1, 2, 3].map((i) => x[i] + (y[i] - x[i]) * t) as Rgba);
}

/** RGB in 0–1 for Babylon colours (game/ converts). */
export const rgb01 = (css: string): [number, number, number] => {
  const [r, g, b] = parseCss(css);
  return [r / 255, g / 255, b / 255];
};
