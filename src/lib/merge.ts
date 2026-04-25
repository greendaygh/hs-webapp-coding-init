import { promises as fs } from 'node:fs';
import path from 'node:path';

/**
 * JSON deep merge. 객체는 키 병합, 배열은 primitive dedupe.
 * source가 우선 (target 값을 덮어씀). 충돌하지 않는 키는 양쪽에서 보존.
 */
export function deepMerge<T = unknown>(target: unknown, source: unknown): T {
  if (Array.isArray(target) && Array.isArray(source)) {
    const merged = [...target, ...source];
    // primitive dedupe (객체 요소는 dedupe 안 함 — 의미 모호)
    const allPrimitive = merged.every((v) => v === null || typeof v !== 'object');
    if (allPrimitive) {
      return [...new Set(merged)] as unknown as T;
    }
    return merged as unknown as T;
  }
  if (isPlainObject(target) && isPlainObject(source)) {
    const out: Record<string, unknown> = { ...(target as Record<string, unknown>) };
    for (const [k, v] of Object.entries(source as Record<string, unknown>)) {
      if (k in out) {
        out[k] = deepMerge(out[k], v);
      } else {
        out[k] = v;
      }
    }
    return out as unknown as T;
  }
  return source as T;
}

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

/**
 * §5.1.5 — 대상 파일 부재 시 빈 객체에서 시작해서 source를 그대로 적용.
 * 부모 디렉터리 자동 생성.
 */
export async function mergeJsonFile(
  toPath: string,
  source: unknown,
): Promise<'merged' | 'created'> {
  await fs.mkdir(path.dirname(toPath), { recursive: true });
  let existing: unknown = {};
  let exists = false;
  try {
    const raw = await fs.readFile(toPath, 'utf-8');
    existing = raw.trim() ? JSON.parse(raw) : {};
    exists = true;
  } catch (err: unknown) {
    if ((err as NodeJS.ErrnoException).code !== 'ENOENT') throw err;
  }
  const merged = deepMerge(existing, source);
  await fs.writeFile(toPath, JSON.stringify(merged, null, 2) + '\n', 'utf-8');
  return exists ? 'merged' : 'created';
}
