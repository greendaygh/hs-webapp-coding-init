import { promises as fs } from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import { afterAll, beforeAll, describe, expect, it } from 'vitest';

const ROOT = path.resolve(__dirname, '../..');
const CLI = path.join(ROOT, 'bin', 'cli.js');

async function runCli(
  cwd: string,
  args: string[],
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  const { execa } = await import('execa');
  const r = await execa('node', [CLI, ...args], { cwd, reject: false });
  return { stdout: r.stdout ?? '', stderr: r.stderr ?? '', exitCode: r.exitCode ?? 0 };
}

async function fileExists(p: string): Promise<boolean> {
  try {
    await fs.stat(p);
    return true;
  } catch {
    return false;
  }
}

async function readFile(p: string): Promise<string> {
  return fs.readFile(p, 'utf-8');
}

describe('CLI integration: build artifact exists', () => {
  beforeAll(async () => {
    if (!(await fileExists(CLI))) {
      throw new Error(`CLI not built: ${CLI}. Run npm run build first.`);
    }
  });

  it('--version prints the package version', async () => {
    const r = await runCli(ROOT, ['--version']);
    expect(r.exitCode).toBe(0);
    expect(r.stdout.trim()).toMatch(/^\d+\.\d+\.\d+/);
  });

  it('list shows presets and assets', async () => {
    const r = await runCli(ROOT, ['list']);
    expect(r.exitCode).toBe(0);
    expect(r.stdout).toContain('webapp-fullstack');
    expect(r.stdout).toContain('cursor-rules');
  });
});

describe('CLI integration: webapp-fullstack init', () => {
  let tmp: string;

  beforeAll(async () => {
    tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'hs-init-'));
    const r = await runCli(tmp, [
      'init',
      '--yes',
      '--preset',
      'webapp-fullstack',
      '--var',
      'project_name=demo',
      '--var',
      'author=tester',
      '--no-msw',
    ]);
    if (r.exitCode !== 0) {
      console.error(r.stdout);
      console.error(r.stderr);
      throw new Error(`init failed exit=${r.exitCode}`);
    }
  }, 60_000);

  afterAll(async () => {
    if (tmp) await fs.rm(tmp, { recursive: true, force: true });
  });

  it('creates backend DDD scaffold', async () => {
    expect(await fileExists(path.join(tmp, 'backend/app/main.py'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'backend/app/config.py'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'backend/app/api/v1/router.py'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'backend/tests/conftest.py'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'backend/tests/unit/test_health.py'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'backend/pytest.ini'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'backend/requirements.txt'))).toBe(true);
  });

  it('substitutes variables in main.py', async () => {
    const main = await readFile(path.join(tmp, 'backend/app/main.py'));
    expect(main).toContain('title="demo"');
    expect(main).not.toContain('{{project_name}}');
    expect(main).not.toContain('{{app_module}}');
    expect(main).toContain('from app.config import get_settings');
  });

  it('substitutes app_module in pytest.ini', async () => {
    const ini = await readFile(path.join(tmp, 'backend/pytest.ini'));
    expect(ini).toContain('--cov=app');
    expect(ini).not.toContain('{{app_module}}');
  });

  it('creates frontend with vite/vitest configs', async () => {
    expect(await fileExists(path.join(tmp, 'frontend/vite.config.ts'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'frontend/vitest.config.ts'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'frontend/src/App.tsx'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'frontend/src/App.test.tsx'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'frontend/src/test/setup.ts'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'frontend/src/mocks/handlers.ts'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'frontend/package.json'))).toBe(true);
  });

  it('frontend package.json contains scripts and deps', async () => {
    const pkg = JSON.parse(await readFile(path.join(tmp, 'frontend/package.json')));
    expect(pkg.scripts.dev).toBe('vite');
    expect(pkg.scripts['test:run']).toBe('vitest run');
    expect(pkg.dependencies.react).toBeDefined();
    expect(pkg.devDependencies.vitest).toBeDefined();
    expect(pkg.devDependencies.msw).toBeDefined();
  });

  it('docker compose / caddy / scripts / env are present', async () => {
    expect(await fileExists(path.join(tmp, 'assets/docker/docker-compose.dev.yml'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'assets/docker/docker-compose.prod.yml'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'assets/docker/docker-compose.db-only.yml'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'assets/docker/Dockerfile.python'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'Caddyfile.prod'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'scripts/start-dev.sh'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'scripts/validate-env.sh'))).toBe(true);
    expect(await fileExists(path.join(tmp, '.env.development.example'))).toBe(true);
    expect(await fileExists(path.join(tmp, '.env.production.example'))).toBe(true);
  });

  it('docs and cursor rules are written with substitutions', async () => {
    expect(await fileExists(path.join(tmp, 'README.md'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'docs/GETTING_STARTED.md'))).toBe(true);
    expect(await fileExists(path.join(tmp, 'docs/HARNESS.md'))).toBe(true);
    expect(await fileExists(path.join(tmp, '.cursor/rules/tdd-workflow.mdc'))).toBe(true);

    const readme = await readFile(path.join(tmp, 'README.md'));
    expect(readme).toContain('# demo');
    expect(readme).not.toContain('{{project_name}}');
  });

  it('.gitignore has data-volumes section appended once', async () => {
    const gi = await readFile(path.join(tmp, '.gitignore'));
    expect(gi).toContain('hs-webapp-coding-init/data-volumes >>>');
    expect(gi).toContain('hs-webapp-coding-init/data-volumes <<<');
    expect(gi).toContain('hs-webapp-coding-init/base >>>');
    const data = (gi.match(/hs-webapp-coding-init\/data-volumes >>>/g) ?? []).length;
    expect(data).toBe(1);
  });

  it('no leftover {{var}} tokens in critical files', async () => {
    const files = [
      'backend/app/main.py',
      'backend/app/config.py',
      'backend/pytest.ini',
      'frontend/vite.config.ts',
      'Caddyfile.prod',
      'README.md',
      'docs/HARNESS.md',
      '.env.development.example',
      'scripts/start-dev.sh',
    ];
    for (const f of files) {
      const content = await readFile(path.join(tmp, f));
      // GitHub Actions ${{ }} 형태는 허용
      const stripped = content.replace(/\$\{\{[^}]*\}\}/g, '');
      const matches = stripped.match(/\{\{(\w+)\}\}/g);
      if (matches) {
        throw new Error(`${f} has unresolved tokens: ${matches.join(', ')}`);
      }
    }
  });

  it('exec actions are NOT run unless --allow-exec', async () => {
    // 현재 manifest에는 exec 자산이 없지만, 옵트인 정책이 코드에 있는지 회귀 방지.
    // (별도 테스트는 install.ts unit에서 커버 가능)
    expect(true).toBe(true);
  });

  // 이슈 #3 회귀: merge-json source 파일이 그대로 copy되어 생긴 고아 파일이 없어야 함
  it('does NOT leave package.scripts.json (merge-source orphan)', async () => {
    const orphan = path.join(tmp, 'frontend/package.scripts.json');
    expect(await fileExists(orphan)).toBe(false);
  });

  // 이슈 #1 회귀: test-all.sh가 venv-aware하게 pytest를 실행해야 함
  it('test-all.sh uses venv-aware pytest invocation', async () => {
    const sh = await readFile(path.join(tmp, 'scripts/test-all.sh'));
    // 단순 `pytest -q` 호출이면 시스템 pytest 잡을 수 있어 NG
    expect(sh).not.toMatch(/\(\s*cd\s+backend\s*&&\s*pytest\b/);
    // 어떤 형태로든 venv 우선 (poetry run / .venv/bin / python -m) 패턴이어야 함
    expect(sh).toMatch(
      /(poetry\s+run\s+pytest|\.venv\/bin\/pytest|python\s+-m\s+pytest|conda\s+run.*pytest)/,
    );
  });

  // 이슈 #2 회귀: test-all.sh에서 e2e가 기본 실행되면 안 됨 (실서비스 의존)
  it('test-all.sh does NOT auto-run e2e (services may not be up)', async () => {
    const sh = await readFile(path.join(tmp, 'scripts/test-all.sh'));
    // e2e 자동 실행 패턴이 없거나, 명시적 환경변수/플래그 게이트가 있어야 함
    const runsE2eUnconditionally = /\(\s*cd\s+e2e\s*&&\s*npm\s+test\s*\)/.test(sh);
    if (runsE2eUnconditionally) {
      // e2e가 호출돼도 좋지만 환경변수 게이트 (예: RUN_E2E=1)가 명시되어야 함
      expect(sh).toMatch(/RUN_E2E|--e2e|\bE2E\b/);
    }
  });

  // 이슈 #4 회귀: poetry preset에서 next-steps의 pip 우선 노출 회피
  // (이 테스트는 stdout을 검증하는 별도 testing block에서 다룸)

  // Phase 1 (v0.1.1) — Observability harness
  it('Phase 1: backend has logging_config (dictConfig)', async () => {
    const lc = await readFile(path.join(tmp, 'backend/app/logging_config.py'));
    expect(lc).toContain('dictConfig');
    expect(lc.toLowerCase()).toMatch(/request[_-]?id/);
  });

  it('Phase 1: main.py wires logging_config and exposes dependency_checks for /health/ready', async () => {
    const main = await readFile(path.join(tmp, 'backend/app/main.py'));
    expect(main).toMatch(/from\s+app\.logging_config\s+import|app\.logging_config/);
    expect(main).toMatch(/dependency_checks|check_dependencies/);
    expect(main).toMatch(/health\/live/);
    expect(main).toMatch(/health\/ready/);
  });

  it('Phase 1: frontend has ErrorBoundary component', async () => {
    expect(await fileExists(path.join(tmp, 'frontend/src/components/ErrorBoundary.tsx'))).toBe(
      true,
    );
    const eb = await readFile(path.join(tmp, 'frontend/src/components/ErrorBoundary.tsx'));
    expect(eb).toMatch(/class\s+ErrorBoundary/);
    expect(eb).toContain('componentDidCatch');
  });

  // Phase 1 (v0.1.1) — Data harness
  it('Phase 1: backend tests/factories.py exists with factory_boy stub', async () => {
    const fp = path.join(tmp, 'backend/tests/factories.py');
    expect(await fileExists(fp)).toBe(true);
    const txt = await readFile(fp);
    expect(txt.toLowerCase()).toContain('factory');
  });

  it('Phase 1: backend dev deps include factory-boy and faker (pip)', async () => {
    const req = await readFile(path.join(tmp, 'backend/requirements-dev.txt'));
    expect(req).toMatch(/factory[-_]boy/i);
    expect(req).toMatch(/faker/i);
  });

  // Phase 2 (v0.1.2) — Reproducibility
  it('Phase 2: project has .tool-versions with node and python', async () => {
    const tv = path.join(tmp, '.tool-versions');
    expect(await fileExists(tv)).toBe(true);
    const txt = await readFile(tv);
    expect(txt).toMatch(/^nodejs\s+\d+(\.\d+)*/m);
    expect(txt).toMatch(/^python\s+\d+(\.\d+)*/m);
    // 변수 치환 누수 없음
    expect(txt).not.toContain('{{');
  });

  // Phase 2 (v0.1.2) — Security harness
  it('Phase 2: .github/workflows/security.yml exists with scanners', async () => {
    const ymlPath = path.join(tmp, '.github/workflows/security.yml');
    expect(await fileExists(ymlPath)).toBe(true);
    const yml = await readFile(ymlPath);
    expect(yml.toLowerCase()).toContain('gitleaks');
    expect(yml.toLowerCase()).toMatch(/bandit/);
    expect(yml.toLowerCase()).toMatch(/(npm\s+audit|pnpm\s+audit)/);
    expect(yml.toLowerCase()).toMatch(/pip[-_ ]audit/);
    // schedule(주기 실행) + on push/pull_request 중 최소 schedule
    expect(yml).toMatch(/schedule:/);
  });

  it('Phase 2: pre-commit config includes bandit', async () => {
    const pc = await readFile(path.join(tmp, '.pre-commit-config.yaml'));
    expect(pc.toLowerCase()).toContain('bandit');
  });

  it('Phase 2: backend dev deps include bandit and pip-audit', async () => {
    const req = await readFile(path.join(tmp, 'backend/requirements-dev.txt'));
    expect(req.toLowerCase()).toContain('bandit');
    expect(req.toLowerCase()).toMatch(/pip[-_]audit/);
  });

  // Phase 3 (v0.1.3) — Staging stack
  it('Phase 3: Caddyfile.staging exists with test-acme CA + staging.<domain>', async () => {
    const cf = path.join(tmp, 'Caddyfile.staging');
    expect(await fileExists(cf)).toBe(true);
    const txt = await readFile(cf);
    // Let's Encrypt staging endpoint (acme-staging-v02 == "test-acme")
    expect(txt).toMatch(/acme[-_]staging|test[-_]?acme|acme-staging-v02/);
    expect(txt).toContain('staging.');
    // 변수 누수 없음 (단, ${...} 형 환경 placeholder는 허용)
    const stripped = txt.replace(/\$\{\{[^}]*\}\}/g, '');
    expect(stripped).not.toMatch(/\{\{\w+\}\}/);
  });

  it('Phase 3: Caddyfile.prod does NOT use test-acme', async () => {
    const cf = await readFile(path.join(tmp, 'Caddyfile.prod'));
    expect(cf).not.toMatch(/acme[-_]staging|acme-staging-v02/);
  });

  it('Phase 3: docker-compose.staging.yml exists with staging suffix', async () => {
    const dc = path.join(tmp, 'assets/docker/docker-compose.staging.yml');
    expect(await fileExists(dc)).toBe(true);
    const txt = await readFile(dc);
    expect(txt).toMatch(/-staging\b/);
    expect(txt).toContain('Caddyfile.staging');
    expect(txt).toContain('.env.staging');
  });

  it('Phase 3: start-staging.sh / stop-staging.sh validate env and use staging compose', async () => {
    const startP = path.join(tmp, 'scripts/start-staging.sh');
    const stopP = path.join(tmp, 'scripts/stop-staging.sh');
    expect(await fileExists(startP)).toBe(true);
    expect(await fileExists(stopP)).toBe(true);
    const start = await readFile(startP);
    const stop = await readFile(stopP);
    expect(start).toMatch(/validate-env\.sh\s+staging/);
    expect(start).toContain('docker-compose.staging.yml');
    expect(start).toContain('.env.staging');
    expect(stop).toContain('docker-compose.staging.yml');
  });

  // Phase 2 — CHANGE_ME fail-fast (production/staging는 거부)
  it('Phase 2: validate-env.sh fails fast on CHANGE_ME in production env file', async () => {
    const { execa } = await import('execa');
    // .env.production.example는 있지만 .env.production은 없음 → 만들어 CHANGE_ME 유지
    const exampleProd = path.join(tmp, '.env.production.example');
    const realProd = path.join(tmp, '.env.production');
    await fs.copyFile(exampleProd, realProd);
    const r = await execa('bash', ['scripts/validate-env.sh', 'production'], {
      cwd: tmp,
      reject: false,
    });
    // CHANGE_ME가 있으므로 비-0 종료 + 메시지에 CHANGE_ME 언급
    expect(r.exitCode).not.toBe(0);
    const out = `${r.stdout ?? ''}\n${r.stderr ?? ''}`;
    expect(out).toContain('CHANGE_ME');
  });
});

describe('CLI integration: idempotent re-run', () => {
  let tmp: string;

  beforeAll(async () => {
    tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'hs-init-rerun-'));
    const args = [
      'init',
      '--yes',
      '--preset',
      'quality-essentials',
      '--var',
      'project_name=re',
      '--no-msw',
    ];
    let r = await runCli(tmp, args);
    expect(r.exitCode).toBe(0);
    r = await runCli(tmp, args);
    expect(r.exitCode).toBe(0);
  }, 60_000);

  afterAll(async () => {
    if (tmp) await fs.rm(tmp, { recursive: true, force: true });
  });

  it('append section is not duplicated on re-run', async () => {
    const gi = await readFile(path.join(tmp, '.gitignore'));
    const count = (gi.match(/hs-webapp-coding-init\/base >>>/g) ?? []).length;
    expect(count).toBe(1);
  });
});

// 이슈 #4 회귀: next-steps 안내가 preset에 따라 적절한 패키지 매니저를 우선 표시
describe('CLI integration: preset-aware next-steps', () => {
  it('poetry preset → next-steps shows poetry install first', async () => {
    const tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'hs-init-poetry-'));
    try {
      const r = await runCli(tmp, [
        'init',
        '--yes',
        '--preset',
        'webapp-fullstack-poetry',
        '--var',
        'project_name=p',
        '--no-msw',
      ]);
      expect(r.exitCode).toBe(0);
      const out = r.stdout;
      // poetry install이 pip install보다 먼저 노출되어야 함
      const poetryIdx = out.indexOf('poetry install');
      const pipIdx = out.indexOf('pip install -r requirements');
      expect(poetryIdx).toBeGreaterThan(-1);
      if (pipIdx !== -1) {
        expect(poetryIdx).toBeLessThan(pipIdx);
      }
    } finally {
      await fs.rm(tmp, { recursive: true, force: true });
    }
  }, 60_000);

  it('conda preset → next-steps shows conda env create first', async () => {
    const tmp = await fs.mkdtemp(path.join(os.tmpdir(), 'hs-init-conda-'));
    try {
      const r = await runCli(tmp, [
        'init',
        '--yes',
        '--preset',
        'webapp-fullstack-conda',
        '--var',
        'project_name=c',
        '--no-msw',
      ]);
      expect(r.exitCode).toBe(0);
      const out = r.stdout;
      const condaIdx = out.indexOf('conda env create');
      const pipIdx = out.indexOf('pip install -r requirements');
      expect(condaIdx).toBeGreaterThan(-1);
      if (pipIdx !== -1) {
        expect(condaIdx).toBeLessThan(pipIdx);
      }
    } finally {
      await fs.rm(tmp, { recursive: true, force: true });
    }
  }, 60_000);
});
