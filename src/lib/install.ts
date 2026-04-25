import { promises as fs } from 'node:fs';
import path from 'node:path';

import { appendFile } from './append.js';
import { copyAsset, loadJsonWithVars } from './io.js';
import {
  AssetEntry,
  AssetAction,
  Manifest,
  PresetEntry,
  findAsset,
  loadManifest,
  loadPreset,
} from './manifest.js';
import { mergeJsonFile } from './merge.js';
import { evalWhen, render } from './template.js';

export interface InstallContext {
  rootDir: string;
  cwd: string;
  vars: Record<string, string>;
  overwriteMode: 'skip-existing' | 'force';
  allowExec: boolean;
  dryRun: boolean;
  log: (msg: string) => void;
}

export interface InstallReport {
  installedAssets: string[];
  skippedAssets: string[];
  filesWritten: number;
  filesSkipped: number;
  warnings: string[];
  postMessages: string[];
}

export async function installAsset(
  asset: AssetEntry,
  ctx: InstallContext,
  report: InstallReport,
): Promise<void> {
  if (!evalWhen(asset.when, ctx.vars)) {
    report.skippedAssets.push(`${asset.id} (when=false)`);
    ctx.log(`  · skip ${asset.id} (when=${asset.when} → false)`);
    return;
  }
  ctx.log(`▸ ${asset.id}${asset.description ? ` — ${asset.description}` : ''}`);
  for (const action of asset.actions) {
    await runAction(action, ctx, report);
  }
  report.installedAssets.push(asset.id);
  if (asset.postMessage) {
    report.postMessages.push(render(asset.postMessage, ctx.vars).text);
  }
}

async function runAction(
  action: AssetAction,
  ctx: InstallContext,
  report: InstallReport,
): Promise<void> {
  switch (action.type) {
    case 'copy': {
      const fromAbs = path.resolve(ctx.rootDir, render(action.from, ctx.vars).text);
      const toRel = render(action.to, ctx.vars).text;
      if (ctx.dryRun) {
        ctx.log(`    copy ${action.from} → ${toRel}`);
        return;
      }
      const r = await copyAsset({
        from: fromAbs,
        to: toRel,
        cwd: ctx.cwd,
        vars: ctx.vars,
        overwriteMode: ctx.overwriteMode,
      });
      report.filesWritten += r.files;
      report.filesSkipped += r.skipped;
      ctx.log(`    copy ${action.from} → ${toRel} (${r.files} files, ${r.skipped} skipped)`);
      return;
    }
    case 'merge-json': {
      const sourceAbs = path.resolve(ctx.rootDir, action.source);
      const toAbs = path.resolve(ctx.cwd, render(action.to, ctx.vars).text);
      if (ctx.dryRun) {
        ctx.log(`    merge-json ${action.source} → ${action.to}`);
        return;
      }
      const src = await loadJsonWithVars(sourceAbs, ctx.vars);
      const r = await mergeJsonFile(toAbs, src);
      report.filesWritten += 1;
      ctx.log(`    merge-json → ${path.relative(ctx.cwd, toAbs)} (${r})`);
      return;
    }
    case 'append': {
      const sourceAbs = path.resolve(ctx.rootDir, action.source);
      const toAbs = path.resolve(ctx.cwd, render(action.to, ctx.vars).text);
      if (ctx.dryRun) {
        ctx.log(`    append [${action.section}] ${action.source} → ${action.to}`);
        return;
      }
      const raw = await fs.readFile(sourceAbs, 'utf-8');
      const body = render(raw, ctx.vars).text;
      const r = await appendFile(toAbs, body, {
        section: action.section,
        dedupe: action.dedupe,
      });
      report.filesWritten += 1;
      ctx.log(`    append [${action.section}] → ${path.relative(ctx.cwd, toAbs)} (${r})`);
      return;
    }
    case 'exec': {
      if (!ctx.allowExec) {
        report.warnings.push(
          `exec skipped (use --allow-exec to enable): ${action.description ?? action.cmd}`,
        );
        ctx.log(`    exec SKIPPED (opt-in): ${action.cmd}`);
        return;
      }
      ctx.log(`    exec: ${action.cmd}`);
      if (ctx.dryRun) return;
      const { execa } = await import('execa');
      const [bin, ...args] = action.cmd.split(/\s+/);
      await execa(bin, args, { cwd: ctx.cwd, stdio: 'inherit' });
      return;
    }
  }
}

export async function installAssets(
  ids: string[],
  manifest: Manifest,
  ctx: InstallContext,
): Promise<InstallReport> {
  const report: InstallReport = {
    installedAssets: [],
    skippedAssets: [],
    filesWritten: 0,
    filesSkipped: 0,
    warnings: [],
    postMessages: [],
  };
  for (const id of ids) {
    const asset = findAsset(manifest, id);
    if (!asset) {
      report.warnings.push(`unknown asset id: ${id}`);
      continue;
    }
    await installAsset(asset, ctx, report);
  }
  return report;
}

/**
 * Preset 적용. preset.defaults는 vars의 (CLI 입력보다 낮은 우선순위) 위에 깔림.
 * 호출부에서 preset.defaults를 vars에 합쳐서 ctx로 넘긴 뒤, 자산 ID 배열을 installAssets에 전달.
 */
export async function applyPreset(
  presetId: string,
  manifest: Manifest,
  ctx: InstallContext,
): Promise<InstallReport> {
  const preset = await loadPreset(ctx.rootDir, presetId);
  return installAssets(preset.assets, manifest, ctx);
}

export { loadManifest, loadPreset };
