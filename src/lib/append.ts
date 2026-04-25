import { promises as fs } from 'node:fs';
import path from 'node:path';

function escapeRe(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/**
 * 섹션 마커 기반 멱등 append.
 *
 *   <section> >>>
 *   <body>
 *   <section> <<<
 *
 * 같은 마커가 이미 있으면 그 사이 본문을 새 본문으로 교체 (dedupe).
 * 없으면 파일 끝에 append.
 */
export function appendSection(existing: string, section: string, body: string): string {
  const start = `${section} >>>`;
  const end = `${section} <<<`;
  const block = `\n${start}\n${body.trim()}\n${end}\n`;
  const re = new RegExp(`\\n?${escapeRe(start)}[\\s\\S]*?${escapeRe(end)}\\n?`);
  if (re.test(existing)) {
    return existing.replace(re, block);
  }
  return existing.trimEnd() + block;
}

/**
 * §5.1.5 — 대상 파일 부재 시 새 파일 생성.
 * 부모 디렉터리 자동 생성.
 */
export async function appendFile(
  toPath: string,
  body: string,
  opts: { section?: string; dedupe?: boolean },
): Promise<'appended' | 'created' | 'updated'> {
  await fs.mkdir(path.dirname(toPath), { recursive: true });
  let existing = '';
  let exists = false;
  try {
    existing = await fs.readFile(toPath, 'utf-8');
    exists = true;
  } catch (err: unknown) {
    if ((err as NodeJS.ErrnoException).code !== 'ENOENT') throw err;
  }
  if (opts.section) {
    const before = existing;
    const next = appendSection(existing, opts.section, body);
    await fs.writeFile(toPath, next, 'utf-8');
    if (!exists) return 'created';
    return before.includes(`${opts.section} >>>`) ? 'updated' : 'appended';
  }
  // 마커 없는 단순 append (현재 자산은 모두 section 사용 — fallback 용도)
  const next = (existing.trimEnd() + '\n' + body.trim() + '\n').trimStart();
  await fs.writeFile(toPath, next, 'utf-8');
  return exists ? 'appended' : 'created';
}
