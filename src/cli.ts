import path from 'node:path';

import { Command } from 'commander';
import pc from 'picocolors';

import { runAdd } from './commands/add.js';
import { runInit } from './commands/init.js';
import { runList } from './commands/list.js';
import { runPreset } from './commands/preset.js';

declare const __dirname: string;
function getRootDir(): string {
  // CJS: __dirname → dist/, 패키지 루트는 ../
  return path.resolve(__dirname, '..');
}

// package.json에서 version 읽기 (런타임)
async function getVersion(rootDir: string): Promise<string> {
  const fs = await import('node:fs/promises');
  try {
    const pkg = JSON.parse(await fs.readFile(path.join(rootDir, 'package.json'), 'utf-8'));
    return pkg.version ?? '0.0.0';
  } catch {
    return '0.0.0';
  }
}

export async function main(argv: string[] = process.argv): Promise<number> {
  const rootDir = getRootDir();
  const program = new Command();
  const version = await getVersion(rootDir);

  program
    .name('hs-webapp-coding-init')
    .description('FastAPI + React 풀스택 부트스트랩 CLI (TDD/Harness/Docs 포함)')
    .version(version);

  program
    .command('init', { isDefault: true })
    .description('현재 디렉터리에 자산 설치')
    .option('-p, --preset <id>', 'preset ID')
    .option('-y, --yes', 'non-interactive (모든 prompt 기본값 사용)')
    .option('-f, --force', '기존 파일 덮어쓰기')
    .option('--dry-run', '실제 쓰기 없이 미리 보기')
    .option('--allow-exec', 'exec action 허용 (보안 opt-in)')
    .option('--no-msw', 'MSW 비활성화')
    .option('--var <key=value...>', '변수 직접 지정 (반복 가능)', collect, [])
    .action(async (cmdOpts) => {
      try {
        await runInit({
          rootDir,
          cwd: process.cwd(),
          preset: cmdOpts.preset,
          yes: cmdOpts.yes,
          force: cmdOpts.force,
          dryRun: cmdOpts.dryRun,
          allowExec: cmdOpts.allowExec,
          noMsw: cmdOpts.msw === false,
          vars: cmdOpts.var,
        });
      } catch (e: unknown) {
        console.error(pc.red(`init failed: ${(e as Error).message}`));
        process.exitCode = 1;
      }
    });

  program
    .command('list')
    .description('preset / asset 목록 출력')
    .action(async () => {
      await runList({ rootDir });
    });

  program
    .command('add <ids...>')
    .description('특정 자산 ID(들) 설치')
    .option('-f, --force', '기존 파일 덮어쓰기')
    .option('--allow-exec', 'exec action 허용')
    .option('--var <key=value...>', '변수 직접 지정', collect, [])
    .action(async (ids: string[], cmdOpts) => {
      try {
        await runAdd({
          rootDir,
          cwd: process.cwd(),
          ids,
          force: cmdOpts.force,
          allowExec: cmdOpts.allowExec,
          vars: cmdOpts.var,
        });
      } catch (e: unknown) {
        console.error(pc.red(`add failed: ${(e as Error).message}`));
        process.exitCode = 1;
      }
    });

  program
    .command('preset [id]')
    .description('preset 상세 보기 (id 생략 시 목록)')
    .action(async (id: string | undefined) => {
      await runPreset({ rootDir, id });
    });

  await program.parseAsync(argv);
  return process.exitCode ?? 0;
}

function collect(value: string, prev: string[]): string[] {
  return [...prev, value];
}

main().catch((e) => {
  console.error(pc.red(`fatal: ${(e as Error).message}`));
  process.exit(1);
});
