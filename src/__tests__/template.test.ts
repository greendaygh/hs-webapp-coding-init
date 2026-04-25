import { describe, expect, it } from 'vitest';

import { evalWhen, render, renderJsonTree } from '../lib/template';

describe('render', () => {
  it('replaces {{var}} with value', () => {
    expect(render('hello {{name}}', { name: 'world' }).text).toBe('hello world');
  });

  it('preserves unknown variables and reports them', () => {
    const r = render('a {{x}} b {{y}} c', { x: '1' });
    expect(r.text).toBe('a 1 b {{y}} c');
    expect(r.missing).toEqual(['y']);
  });

  it('does not touch GitHub Actions ${{ ... }}', () => {
    const r = render('${{ secrets.FOO }} and {{name}}', { name: 'me' });
    expect(r.text).toBe('${{ secrets.FOO }} and me');
  });

  it('replaces multiple occurrences', () => {
    const r = render('{{x}}-{{x}}', { x: 'a' });
    expect(r.text).toBe('a-a');
  });
});

describe('renderJsonTree', () => {
  it('renders string leaves only', () => {
    const out = renderJsonTree({ a: '{{x}}', b: 1, c: ['{{x}}', 2] }, { x: 'X' });
    expect(out).toEqual({ a: 'X', b: 1, c: ['X', 2] });
  });

  it('also renders object keys', () => {
    const out = renderJsonTree({ '{{key}}': 'v' }, { key: 'name' });
    expect(out).toEqual({ name: 'v' });
  });
});

describe('evalWhen', () => {
  it('returns true when when is undefined', () => {
    expect(evalWhen(undefined, {})).toBe(true);
  });

  it('returns true when var is "true"', () => {
    expect(evalWhen('{{enable}}', { enable: 'true' })).toBe(true);
  });

  it('returns false when var is anything else', () => {
    expect(evalWhen('{{enable}}', { enable: 'false' })).toBe(false);
    expect(evalWhen('{{enable}}', {})).toBe(false);
  });

  it('rejects compound expressions', () => {
    expect(() => evalWhen('{{a}} && {{b}}', { a: 'true', b: 'true' })).toThrow();
  });
});
