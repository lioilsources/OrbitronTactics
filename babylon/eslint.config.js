import tseslint from 'typescript-eslint';

// Layer boundaries: rules/ is pure (no Babylon, no DOM, no game/ or ui/),
// ui/ is DOM only (no Babylon). game/ may use everything.
export default tseslint.config(
  { ignores: ['dist/**', 'node_modules/**', 'public/**'] },
  ...tseslint.configs.recommended,
  {
    files: ['src/rules/**'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [
          { group: ['@babylonjs/*'], message: 'rules/ must not depend on Babylon.' },
          { group: ['**/game/*', '**/game/**', '**/ui/*', '**/ui/**'], message: 'rules/ must not import game/ or ui/.' },
        ],
      }],
      'no-restricted-globals': ['error', 'document', 'window', 'navigator', 'localStorage', 'performance'],
    },
  },
  {
    files: ['src/ui/**'],
    rules: {
      'no-restricted-imports': ['error', {
        patterns: [
          { group: ['@babylonjs/*'], message: 'ui/ is a DOM overlay; Babylon lives in game/.' },
          { group: ['**/game/*', '**/game/**'], message: 'ui/ must not import game/.' },
        ],
      }],
    },
  },
);
