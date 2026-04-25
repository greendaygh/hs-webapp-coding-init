import pc from 'picocolors';

type PyManager = 'poetry' | 'conda' | 'pip';

function detectPyManager(presetId?: string): PyManager {
  if (!presetId) return 'pip';
  if (presetId.includes('poetry')) return 'poetry';
  if (presetId.includes('conda')) return 'conda';
  return 'pip';
}

function backendInstallLines(backendDir: string, pm: PyManager): string[] {
  switch (pm) {
    case 'poetry':
      return [
        `3. cd ${backendDir} && poetry install`,
        `   (또는 pip preset 사용 시: pip install -r requirements-dev.txt)`,
      ];
    case 'conda':
      return [
        `3. cd ${backendDir} && conda env create -f environment.yml && conda activate ${backendDir}`,
        `   (또는 pip preset 사용 시: pip install -r requirements-dev.txt)`,
      ];
    default:
      return [
        `3. cd ${backendDir} && pip install -r requirements-dev.txt`,
        `   (또는 poetry install / conda env create -f environment.yml)`,
      ];
  }
}

export function printNextSteps(vars: Record<string, string>, presetId?: string): void {
  const pm = detectPyManager(presetId);
  const lines = [
    'Next steps' + (presetId ? ` (preset: ${presetId})` : ''),
    '',
    `1. cp .env.development.example .env.development`,
    `2. bash scripts/start-db.sh`,
    ...backendInstallLines(vars.backend_dir ?? 'backend', pm),
    `4. cd ${vars.frontend_dir} && npm ci`,
    `5. bash scripts/test-all.sh        # TDD 1일차 그린 확인`,
    `6. bash scripts/start-dev.sh       # http://localhost:${vars.frontend_dev_port}`,
    '',
    'Docs: docs/GETTING_STARTED.md / TESTING.md / HARNESS.md',
  ];
  const width = Math.max(...lines.map((l) => l.length)) + 2;
  const top = '┌' + '─'.repeat(width) + '┐';
  const bot = '└' + '─'.repeat(width) + '┘';
  console.log(pc.cyan(top));
  for (const l of lines) {
    console.log(pc.cyan('│ ') + l + ' '.repeat(width - l.length - 1) + pc.cyan('│'));
  }
  console.log(pc.cyan(bot));
}
