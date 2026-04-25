import { promises as fs } from 'node:fs';
import path from 'node:path';

export interface AssetActionCopy {
  type: 'copy';
  from: string;
  to: string;
}
export interface AssetActionMergeJson {
  type: 'merge-json';
  to: string;
  source: string;
}
export interface AssetActionAppend {
  type: 'append';
  to: string;
  source: string;
  section: string;
  dedupe?: boolean;
}
export interface AssetActionExec {
  type: 'exec';
  cmd: string;
  optIn: true;
  description?: string;
}

export type AssetAction =
  | AssetActionCopy
  | AssetActionMergeJson
  | AssetActionAppend
  | AssetActionExec;

export interface AssetEntry {
  id: string;
  description?: string;
  category?: string;
  when?: string;
  actions: AssetAction[];
  postMessage?: string;
}

export interface Manifest {
  schema: string;
  version: string;
  assets: AssetEntry[];
}

export interface PresetEntry {
  id: string;
  description?: string;
  assets: string[];
  defaults?: Record<string, string>;
}

export async function loadManifest(rootDir: string): Promise<Manifest> {
  const p = path.join(rootDir, 'manifest.json');
  const raw = await fs.readFile(p, 'utf-8');
  return JSON.parse(raw) as Manifest;
}

export async function loadPreset(rootDir: string, id: string): Promise<PresetEntry> {
  const p = path.join(rootDir, 'presets', `${id}.json`);
  const raw = await fs.readFile(p, 'utf-8');
  return JSON.parse(raw) as PresetEntry;
}

export async function listPresets(rootDir: string): Promise<string[]> {
  const dir = path.join(rootDir, 'presets');
  const files = await fs.readdir(dir);
  return files.filter((f) => f.endsWith('.json')).map((f) => f.replace(/\.json$/, ''));
}

export function findAsset(manifest: Manifest, id: string): AssetEntry | undefined {
  return manifest.assets.find((a) => a.id === id);
}
