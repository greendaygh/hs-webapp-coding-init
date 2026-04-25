import pc from 'picocolors';

import { installAssets, loadManifest } from '../lib/install.js';
import { resolveVars } from '../lib/vars.js';

export async function runAdd(opts: {
  rootDir: string;
  cwd: string;
  ids: string[];
  vars?: string[];
  yes?: boolean;
  force?: boolean;
  allowExec?: boolean;
}): Promise<void> {
  const manifest = await loadManifest(opts.rootDir);
  const cliVars: Record<string, string> = {};
  for (const v of opts.vars ?? []) {
    const m = /^([\w]+)=(.*)$/.exec(v);
    if (!m) throw new Error(`invalid --var format: ${v}`);
    cliVars[m[1]] = m[2];
  }
  const vars = resolveVars({ cliVars });
  const ctx = {
    rootDir: opts.rootDir,
    cwd: opts.cwd,
    vars,
    overwriteMode: (opts.force ? 'force' : 'skip-existing') as 'force' | 'skip-existing',
    allowExec: opts.allowExec ?? false,
    dryRun: false,
    log: (msg: string) => console.log(msg),
  };
  const report = await installAssets(opts.ids, manifest, ctx);
  console.log();
  console.log(
    pc.green(
      `✓ installed ${report.installedAssets.length} assets, ${report.filesWritten} files written, ${report.filesSkipped} skipped`,
    ),
  );
  for (const w of report.warnings) console.log(pc.yellow(`  ! ${w}`));
}
