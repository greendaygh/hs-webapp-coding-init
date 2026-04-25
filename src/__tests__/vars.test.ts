import { describe, expect, it } from 'vitest';

import { resolveVars, slugify } from '../lib/vars';

describe('slugify', () => {
  it('lowercases and replaces spaces', () => {
    expect(slugify('My App')).toBe('my-app');
  });

  it('strips punctuation', () => {
    expect(slugify('Hello, World!')).toBe('hello-world');
  });

  it('collapses repeated separators', () => {
    expect(slugify('a__b  c')).toBe('a-b-c');
  });
});

describe('resolveVars precedence', () => {
  it('cliVars wins over prompted, prompted wins over defaults', () => {
    const v = resolveVars({
      defaults: { a: 'd', b: 'd', c: 'd' },
      prompted: { b: 'p', c: 'p' },
      cliVars: { c: 'cli' },
    });
    expect(v.a).toBe('d');
    expect(v.b).toBe('p');
    expect(v.c).toBe('cli');
  });

  it('derives project_slug from project_name', () => {
    const v = resolveVars({ prompted: { project_name: 'My Cool App' } });
    expect(v.project_slug).toBe('my-cool-app');
  });

  it('respects explicit project_slug', () => {
    const v = resolveVars({ prompted: { project_name: 'My App', project_slug: 'custom' } });
    expect(v.project_slug).toBe('custom');
  });

  it('sets is_locale_en from default_locale', () => {
    expect(resolveVars({ prompted: { default_locale: 'en' } }).is_locale_en).toBe('true');
    expect(resolveVars({ prompted: { default_locale: 'ko' } }).is_locale_en).toBe('false');
  });
});
