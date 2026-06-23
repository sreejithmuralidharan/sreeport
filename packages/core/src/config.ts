import fs from "node:fs";
import path from "node:path";
import { createJiti } from "jiti";
import { sreeportConfigSchema } from "./schema.js";
import type { SreeportConfig, SreeportProjectConfig } from "./types.js";

const configNames = [
  "sreeport.config.ts",
  "sreeport.config.mts",
  "sreeport.config.js",
  "sreeport.config.mjs",
  "sreeport.config.cjs",
  "sreeport.config.json"
];

export function defineSreeportConfig(config: SreeportConfig): SreeportConfig {
  return config;
}

export function configCandidates(cwd = process.cwd()): string[] {
  return configNames.map((name) => path.join(cwd, name));
}

export function findProjectConfig(cwd = process.cwd()): string | undefined {
  return configCandidates(cwd).find((candidate) => fs.existsSync(candidate));
}

export async function loadProjectConfig(cwd = process.cwd()): Promise<SreeportConfig> {
  const configPath = findProjectConfig(cwd);
  if (!configPath) return { projects: [] };

  if (configPath.endsWith(".json")) {
    const parsed = JSON.parse(fs.readFileSync(configPath, "utf8"));
    return normalizeConfig(parsed, path.dirname(configPath));
  }

  const jiti = createJiti(import.meta.url, {
    interopDefault: true,
    moduleCache: false
  });
  const loaded = await jiti.import(configPath, { default: true });
  return normalizeConfig(loaded, path.dirname(configPath));
}

export function normalizeConfig(raw: unknown, configDir = process.cwd()): SreeportConfig {
  const parsed = sreeportConfigSchema.parse(raw);
  return {
    projects: parsed.projects.map((project) => normalizeProject(project as SreeportProjectConfig, configDir))
  };
}

export function normalizeProject(
  project: SreeportProjectConfig,
  configDir = process.cwd()
): SreeportProjectConfig {
  const cwd = project.cwd ? path.resolve(configDir, project.cwd) : configDir;
  return {
    ...project,
    cwd,
    browser: project.browser ?? "default",
    framework: project.framework ?? "custom",
    env: project.env ?? {},
    visible: project.visible ?? true
  };
}

export function configTemplate(projectName: string, domain: string, port: number): string {
  return `export default {
  projects: [
    {
      name: "${projectName}",
      domain: "${domain}",
      port: ${port},
      framework: "next",
      browser: "default"
    }
  ]
} satisfies import("@sreeport/core").SreeportConfig;
`;
}
