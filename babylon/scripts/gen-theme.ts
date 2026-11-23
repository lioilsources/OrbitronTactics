// npm run gen: lib/core/theme/board_theme.dart → src/ui/generated/board-theme.ts
// test/theme-sync.test.ts fails when the generated file drifts from the Flutter source.
import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parseBoardTheme, renderBoardTheme } from './dart-theme';

const out = fileURLToPath(new URL('../src/ui/generated/board-theme.ts', import.meta.url));
mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, renderBoardTheme(parseBoardTheme()));
console.log(`wrote ${out}`);
