import path from 'node:path';

import { input, select, confirm } from '@inquirer/prompts';
import pc from 'picocolors';

import { applyPreset, loadManifest, loadPreset } from '../lib/install.js';
import { listPresets } from '../lib/manifest.js';
import { resolveVars } from '../lib/vars.js';

import { printNextSteps } from './next-steps.js';

interface InitOptions {
  preset?: string;
  yes?: boolean;
  force?: boolean;
  dryRun?: boolean;
  allowExec?: boolean;
  vars?: string[];
  noMsw?: boolean;
  rootDir: string;
  cwd: string;
}

function parseCliVars(vars: string[] | undefined): Record<string, string> {
  const out: Record<string, string> = {};
  for (const v of vars ?? []) {
    const m = /^([\w]+)=(.*)$/.exec(v);
    if (!m) throw new Error(`invalid --var format: ${v} (expected key=value)`);
    out[m[1]] = m[2];
  }
  return out;
}

export async function runInit(opts: InitOptions): Promise<void> {
  const manifest = await loadManifest(opts.rootDir);
  const presets = await listPresets(opts.rootDir);

  let presetId = opts.preset;
  let prompted: Record<string, string> = {};

  if (!opts.yes) {
    if (!presetId) {
      presetId = (await select({
        message: 'preset 선택',
        choices: presets.map((p) => ({ value: p, name: p })),
        default: 'webapp-fullstack',
      })) as string;
    }

    prompted.project_name = await input({
      message: 'project name',
      default: path.basename(opts.cwd),
    });
    prompted.author = await input({ message: 'author', default: '' });
    prompted.proxy_domain = await input({ message: 'production domain', default: 'localhost' });
    const locale = await select({
      message: 'default locale',
      choices: [
        { value: 'ko', name: 'ko' },
        { value: 'en', name: 'en' },
      ],
      default: 'ko',
    });
    prompted.default_locale = locale as string;

    if (opts.noMsw === undefined) {
      const useMsw = await confirm({ message: 'MSW(API mock) 활성화?', default: true });
      prompted.enable_msw = useMsw ? 'true' : 'false';
    }
  } else {
    presetId = presetId ?? 'webapp-fullstack';
    prompted.project_name = path.basename(opts.cwd);
  }

  if (opts.noMsw) prompted.enable_msw = 'false';

  const cliVars = parseCliVars(opts.vars);
  const preset = await loadPreset(opts.rootDir, presetId);
  const vars = resolveVars({
    defaults: preset.defaults ?? {},
    prompted,
    cliVars,
  });

  console.log(pc.cyan(`\n▸ preset: ${presetId}`));
  console.log(pc.dim(`  project_name=${vars.project_name} project_slug=${vars.project_slug}`));
  console.log(pc.dim(`  backend_dir=${vars.backend_dir} frontend_dir=${vars.frontend_dir}`));
  console.log();

  const overwriteMode = opts.force ? 'force' : 'skip-existing';
  const ctx = {
    rootDir: opts.rootDir,
    cwd: opts.cwd,
    vars,
    overwriteMode: overwriteMode as 'force' | 'skip-existing',
    allowExec: opts.allowExec ?? false,
    dryRun: opts.dryRun ?? false,
    log: (msg: string) => console.log(msg),
  };

  const report = await applyPreset(presetId, manifest, ctx);

  console.log();
  console.log(
    pc.green(
      `✓ installed ${report.installedAssets.length} assets, ${report.filesWritten} files written, ${report.filesSkipped} skipped`,
    ),
  );

  if (report.skippedAssets.length) {
    console.log(pc.dim(`  skipped (when=false): ${report.skippedAssets.join(', ')}`));
  }
  if (report.warnings.length) {
    console.log(pc.yellow('warnings:'));
    for (const w of report.warnings) console.log(pc.yellow(`  - ${w}`));
  }
  if (report.postMessages.length) {
    console.log();
    console.log(pc.cyan('post-install:'));
    for (const m of report.postMessages) console.log(pc.cyan(`  · ${m}`));
  }

  console.log();
  printNextSteps(vars, presetId);
}
