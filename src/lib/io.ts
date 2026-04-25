import { promises as fs } from 'node:fs';
import path from 'node:path';

import { render, renderJsonTree } from './template.js';

export async function exists(p: string): Promise<boolean> {
  try {
    await fs.stat(p);
    return true;
  } catch (err: unknown) {
    if ((err as NodeJS.ErrnoException).code === 'ENOENT') return false;
    throw err;
  }
}

export async function ensureDir(p: string): Promise<void> {
  await fs.mkdir(p, { recursive: true });
}

/**
 * 디렉터리를 재귀적으로 순회하면서 모든 파일 경로(절대) 반환.
 */
export async function walk(dir: string): Promise<string[]> {
  const out: string[] = [];
  const entries = await fs.readdir(dir, { withFileTypes: true });
  for (const e of entries) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...(await walk(full)));
    else if (e.isFile()) out.push(full);
  }
  return out;
}

/**
 * 자산 from 경로(파일 or 디렉터리)를 to 경로로 복사 + 템플릿 치환.
 *
 * - `.tpl` 확장자: render() 적용 후 `.tpl`만 제거.
 * - 그 외 텍스트 파일: 본문에 `{{var}}`가 있으면 render 적용, 없으면 byte 그대로.
 * - 파일명에도 render 적용 (예: `__project_slug__` 같은 경로 변수는 미지원, `{{}}`만 지원).
 *
 * 충돌 정책 (overwriteMode):
 *  - 'skip-existing' : 기존 파일 보존 (default)
 *  - 'force'         : 덮어쓰기
 */
export async function copyAsset(opts: {
  from: string;
  to: string;
  cwd: string;
  vars: Record<string, string>;
  overwriteMode: 'skip-existing' | 'force';
  binaryExtensions?: string[];
}): Promise<{ files: number; skipped: number; written: string[] }> {
  const stat = await fs.stat(opts.from);
  if (stat.isFile()) {
    return copyOneFile(opts.from, resolveTo(opts.to, opts.cwd, opts.vars), opts);
  }
  // directory
  const files = await walk(opts.from);
  let total = { files: 0, skipped: 0, written: [] as string[] };
  for (const src of files) {
    const rel = path.relative(opts.from, src);
    const renderedRel = render(rel, opts.vars).text;
    const dest = path.resolve(opts.cwd, render(opts.to, opts.vars).text, renderedRel);
    const r = await copyOneFile(src, dest, opts);
    total.files += r.files;
    total.skipped += r.skipped;
    total.written.push(...r.written);
  }
  return total;
}

function resolveTo(to: string, cwd: string, vars: Record<string, string>): string {
  return path.resolve(cwd, render(to, vars).text);
}

const DEFAULT_BINARY_EXTS = ['.png', '.jpg', '.jpeg', '.gif', '.ico', '.woff', '.woff2', '.ttf'];

async function copyOneFile(
  fromAbs: string,
  toAbs: string,
  opts: {
    vars: Record<string, string>;
    overwriteMode: 'skip-existing' | 'force';
    binaryExtensions?: string[];
  },
): Promise<{ files: number; skipped: number; written: string[] }> {
  // .tpl 확장자 처리
  let finalDest = toAbs;
  const isTpl = fromAbs.endsWith('.tpl');
  if (isTpl) {
    finalDest = toAbs.replace(/\.tpl$/, '');
  }

  const isBinary = (opts.binaryExtensions ?? DEFAULT_BINARY_EXTS).some((ext) =>
    fromAbs.toLowerCase().endsWith(ext),
  );

  if (await exists(finalDest)) {
    if (opts.overwriteMode === 'skip-existing') {
      return { files: 0, skipped: 1, written: [] };
    }
  }

  await ensureDir(path.dirname(finalDest));
  if (isBinary) {
    await fs.copyFile(fromAbs, finalDest);
  } else {
    const raw = await fs.readFile(fromAbs, 'utf-8');
    const text = isTpl || raw.includes('{{') ? render(raw, opts.vars).text : raw;
    await fs.writeFile(finalDest, text, 'utf-8');
  }
  return { files: 1, skipped: 0, written: [finalDest] };
}

/**
 * JSON 파일을 읽어서 renderJsonTree 적용 후 객체 반환.
 */
export async function loadJsonWithVars<T = unknown>(
  fromPath: string,
  vars: Record<string, string>,
): Promise<T> {
  const raw = await fs.readFile(fromPath, 'utf-8');
  const obj = JSON.parse(raw);
  return renderJsonTree(obj, vars) as T;
}
