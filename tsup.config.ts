import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/cli.ts'],
  format: ['cjs'],
  target: 'node18',
  outDir: 'dist',
  outExtension: () => ({ js: '.cjs' }),
  clean: true,
  sourcemap: true,
  dts: false,
  splitting: false,
  shims: false,
  banner: {
    js: '#!/usr/bin/env node',
  },
});
