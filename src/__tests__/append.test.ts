import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { appendFile, appendSection } from '../lib/append';

describe('appendSection', () => {
  it('appends with markers when missing', () => {
    const out = appendSection('# existing\n', 'data', 'data/\n*.log');
    expect(out).toContain('data >>>');
    expect(out).toContain('data <<<');
    expect(out).toContain('data/\n*.log');
  });

  it('replaces body for existing section (idempotent)', () => {
    const initial = appendSection('', 'data', 'old/\n');
    const updated = appendSection(initial, 'data', 'new/\n');
    expect(updated).not.toContain('old/');
    expect(updated).toContain('new/');
    const matches = updated.match(/data >>>/g) ?? [];
    expect(matches.length).toBe(1);
  });

  it('preserves other sections', () => {
    let out = appendSection('# .gitignore\n', 'data', 'data/');
    out = appendSection(out, 'logs', 'logs/');
    expect(out).toContain('data >>>');
    expect(out).toContain('logs >>>');
  });
});

describe('appendFile', () => {
  let tmp: string;
  beforeEach(async () => {
    tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'append-'));
  });
  afterEach(async () => {
    await fs.rm(tmp, { recursive: true, force: true });
  });

  it('creates file when missing', async () => {
    const f = path.join(tmp, 'sub', '.gitignore');
    const r = await appendFile(f, 'foo/', { section: 'foo' });
    expect(r).toBe('created');
    expect(await fs.readFile(f, 'utf-8')).toContain('foo >>>');
  });

  it('is idempotent on repeated runs', async () => {
    const f = path.join(tmp, '.gitignore');
    await appendFile(f, 'data/', { section: 'data' });
    await appendFile(f, 'data/', { section: 'data' });
    const text = await fs.readFile(f, 'utf-8');
    const count = (text.match(/data >>>/g) ?? []).length;
    expect(count).toBe(1);
  });
});
