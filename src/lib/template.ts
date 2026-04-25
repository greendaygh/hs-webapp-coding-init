/**
 * §5.1.1 (B1) + §5.3.7 — 변수 치환 엔진.
 *
 * - `{{var}}` 패턴만 치환. `${{ ... }}` (GitHub Actions 표기)는 lookbehind로 제외.
 * - 미정의 변수는 원문 보존 + missing 리스트에 누적.
 * - JSON merge 자산은 renderJsonTree로 string leaf만 치환 (파싱 깨짐 방지).
 */

const VAR_PATTERN = /(?<!\$)\{\{(\w+)\}\}/g;

export interface RenderResult {
  text: string;
  missing: string[];
}

export function render(src: string, vars: Record<string, string>): RenderResult {
  const missing = new Set<string>();
  const out = src.replace(VAR_PATTERN, (match, key: string) => {
    if (key in vars) return vars[key];
    missing.add(key);
    return match;
  });
  return { text: out, missing: [...missing] };
}

/**
 * §5.1.1 (B1): JSON 트리에서 string leaf(키 포함)만 render.
 * 객체/배열 구조는 그대로 보존하고, 숫자/불리언/null은 그대로 통과.
 */
export function renderJsonTree<T>(node: T, vars: Record<string, string>): T {
  if (typeof node === 'string') {
    return render(node, vars).text as unknown as T;
  }
  if (Array.isArray(node)) {
    return node.map((n) => renderJsonTree(n, vars)) as unknown as T;
  }
  if (node !== null && typeof node === 'object') {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(node as Record<string, unknown>)) {
      out[render(k, vars).text] = renderJsonTree(v, vars);
    }
    return out as T;
  }
  return node;
}

/**
 * preset의 `when` 평가. §5.1.2 — 단일 변수 토큰 `{{name}}` 패턴만 허용.
 *  - 평가 결과 문자열이 'true'면 포함, 그 외 (false, 빈, 미정의) 제외.
 *  - 복합식/부정/연산자는 미지원 (positive 명명으로 우회).
 */
export function evalWhen(when: string | undefined, vars: Record<string, string>): boolean {
  if (when === undefined || when === null || when === '') return true;
  const m = /^\{\{(\w+)\}\}$/.exec(when);
  if (!m) {
    throw new Error(
      `'when' must be a single variable token like {{name}}, got: ${JSON.stringify(when)}`,
    );
  }
  const value = vars[m[1]];
  return value === 'true';
}
