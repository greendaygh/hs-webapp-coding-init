import pc from 'picocolors';

import { loadManifest, listPresets, loadPreset } from '../lib/manifest.js';

export async function runList(opts: { rootDir: string }): Promise<void> {
  const manifest = await loadManifest(opts.rootDir);
  const presets = await listPresets(opts.rootDir);

  console.log(pc.bold('Presets'));
  for (const id of presets) {
    const p = await loadPreset(opts.rootDir, id);
    console.log(`  ${pc.cyan(id.padEnd(28))}${p.description ?? ''}`);
  }

  console.log();
  console.log(pc.bold('Assets'));
  for (const a of manifest.assets) {
    console.log(`  ${pc.cyan(a.id.padEnd(28))}${a.description ?? ''}`);
  }
}
