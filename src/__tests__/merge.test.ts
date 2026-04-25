import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import { afterEach, beforeEach, describe, expect, it } from 'vitest';

import { deepMerge, mergeJsonFile } from '../lib/merge';

describe('deepMerge', () => {
  it('merges plain objects', () => {
    expect(deepMerge({ a: 1, b: 2 }, { b: 3, c: 4 })).toEqual({ a: 1, b: 3, c: 4 });
  });

  it('recurses into nested objects', () => {
    expect(deepMerge({ x: { a: 1 } }, { x: { b: 2 } })).toEqual({ x: { a: 1, b: 2 } });
  });

  it('dedupes primitive arrays', () => {
    expect(deepMerge(['a', 'b'], ['b', 'c'])).toEqual(['a', 'b', 'c']);
  });

  it('keeps object array elements without dedupe', () => {
    expect(deepMerge([{ a: 1 }], [{ b: 2 }])).toEqual([{ a: 1 }, { b: 2 }]);
  });
});

describe('mergeJsonFile', () => {
  let tmp: string;
  beforeEach(async () => {
    tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'merge-'));
  });
  afterEach(async () => {
    await fs.rm(tmp, { recursive: true, force: true });
  });

  it('creates file when missing', async () => {
    const f = path.join(tmp, 'new', 'a.json');
    const r = await mergeJsonFile(f, { x: 1 });
    expect(r).toBe('created');
    expect(JSON.parse(await fs.readFile(f, 'utf-8'))).toEqual({ x: 1 });
  });

  it('merges with existing content', async () => {
    const f = path.join(tmp, 'a.json');
    await fs.writeFile(f, JSON.stringify({ a: 1, nested: { x: 1 } }));
    const r = await mergeJsonFile(f, { b: 2, nested: { y: 2 } });
    expect(r).toBe('merged');
    expect(JSON.parse(await fs.readFile(f, 'utf-8'))).toEqual({
      a: 1,
      b: 2,
      nested: { x: 1, y: 2 },
    });
  });
});
