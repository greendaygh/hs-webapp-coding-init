import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { installAssets } from '../lib/install';
import { Manifest } from '../lib/manifest';

describe('install: exec opt-in policy', () => {
  let tmp: string;
  let assets: string;
  beforeEach(async () => {
    tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'inst-'));
    assets = await fs.mkdtemp(path.join(os.tmpdir(), 'inst-assets-'));
  });
  afterEach(async () => {
    await fs.rm(tmp, { recursive: true, force: true });
    await fs.rm(assets, { recursive: true, force: true });
  });

  it('skips exec actions when allowExec is false', async () => {
    const manifest: Manifest = {
      schema: 'test',
      version: '0',
      assets: [
        {
          id: 'dangerous',
          actions: [
            {
              type: 'exec',
              cmd: 'sh -c "echo HACKED > ' + path.join(tmp, 'pwned.txt') + '"',
              optIn: true,
            },
          ],
        },
      ],
    };
    const report = await installAssets(['dangerous'], manifest, {
      rootDir: assets,
      cwd: tmp,
      vars: {},
      overwriteMode: 'skip-existing',
      allowExec: false,
      dryRun: false,
      log: () => {},
    });
    expect(report.warnings.some((w) => /exec skipped/.test(w))).toBe(true);
    let exists = false;
    try {
      await fs.stat(path.join(tmp, 'pwned.txt'));
      exists = true;
    } catch {
      /* expected */
    }
    expect(exists).toBe(false);
  });
});
