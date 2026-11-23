import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';
import { argbToCss, parseBoardTheme, renderBoardTheme } from '../scripts/dart-theme';
import { lerpCss, withAlpha } from '../src/ui/palette';

describe('board theme is generated from Dart', () => {
  it('board-theme.ts matches lib/core/theme/board_theme.dart (run `npm run gen` if not)', () => {
    const src = readFileSync(fileURLToPath(new URL('../src/ui/generated/board-theme.ts', import.meta.url)), 'utf8');
    expect(src).toBe(renderBoardTheme(parseBoardTheme()));
  });

  it('reads the square and power-field colours', () => {
    const t = parseBoardTheme();
    expect(t.lightSquare).toBe(0xff8b7355);
    expect(t.powerFieldColor).toBe(0x6000bcd4);
    expect(Object.keys(t).length).toBeGreaterThanOrEqual(17);
  });

  it('ARGB → CSS', () => {
    expect(argbToCss(0xff8b7355)).toBe('#8B7355');
    expect(argbToCss(0x8800e676)).toBe('rgba(0,230,118,0.5333)');
  });

  it('colour helpers behave like Color.lerp and withValues', () => {
    expect(lerpCss('#000000', '#FFFFFF', 0.5)).toBe('rgba(128,128,128,1)');
    expect(withAlpha('rgba(0,188,212,0.3765)', 0.5)).toBe('rgba(0,188,212,0.5)');
  });
});
