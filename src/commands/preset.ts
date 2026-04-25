import pc from 'picocolors';

import { loadPreset, listPresets, loadManifest, findAsset } from '../lib/manifest.js';

export async function runPreset(opts: { rootDir: string; id?: string }): Promise<void> {
  if (!opts.id) {
    const ids = await listPresets(opts.rootDir);
    console.log(pc.bold('Available presets'));
    for (const id of ids) {
      const p = await loadPreset(opts.rootDir, id);
      console.log(`  ${pc.cyan(id.padEnd(28))}${p.description ?? ''}`);
    }
    return;
  }
  const preset = await loadPreset(opts.rootDir, opts.id);
  const manifest = await loadManifest(opts.rootDir);
  console.log(pc.bold(`Preset: ${preset.id}`));
  if (preset.description) console.log(pc.dim(`  ${preset.description}`));
  console.log();
  if (preset.defaults) {
    console.log(pc.bold('  defaults'));
    for (const [k, v] of Object.entries(preset.defaults)) {
      console.log(`    ${k}=${v}`);
    }
    console.log();
  }
  console.log(pc.bold('  assets'));
  for (const id of preset.assets) {
    const a = findAsset(manifest, id);
    console.log(`    ${pc.cyan(id.padEnd(28))}${a?.description ?? ''}`);
  }
}
