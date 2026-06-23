import fs from "node:fs";
import path from "node:path";
import type { Framework, SreeportProjectConfig } from "./types.js";

export interface ScanOptions {
  root: string;
  startPort?: number;
  limit?: number;
}

export function scanProjects(options: ScanOptions): SreeportProjectConfig[] {
  const root = path.resolve(options.root);
  const startPort = options.startPort ?? 3100;
  const limit = options.limit ?? 50;
  const results: SreeportProjectConfig[] = [];
  walk(root, 3, (dir) => {
    if (results.length >= limit) return;
    const packageJson = path.join(dir, "package.json");
    if (!fs.existsSync(packageJson)) return;

    const pkg = JSON.parse(fs.readFileSync(packageJson, "utf8")) as {
      name?: string;
      dependencies?: Record<string, string>;
      devDependencies?: Record<string, string>;
    };
    const deps = { ...pkg.dependencies, ...pkg.devDependencies };
    const framework: Framework = deps.next ? "next" : deps.vite ? "vite" : "custom";
    const name = safeName(pkg.name ?? path.basename(dir));
    results.push({
      name,
      domain: `${name}.localhost`,
      port: startPort + results.length,
      cwd: dir,
      framework,
      browser: "default",
      visible: true
    });
  });
  return results;
}

function walk(dir: string, depth: number, onDir: (dir: string) => void): void {
  if (depth < 0 || path.basename(dir) === "node_modules" || path.basename(dir).startsWith(".")) return;
  onDir(dir);
  let entries: fs.Dirent[];
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    walk(path.join(dir, entry.name), depth - 1, onDir);
  }
}

function safeName(input: string): string {
  return input
    .replace(/^@/, "")
    .replaceAll("/", "-")
    .replace(/[^a-zA-Z0-9._-]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .toLowerCase();
}
