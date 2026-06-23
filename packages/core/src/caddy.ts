import fs from "node:fs";
import path from "node:path";
import type { SreeportProjectConfig } from "./types.js";

export interface CaddyOptions {
  listenPort?: number;
  fallbackMessage?: string;
}

export function generateCaddyfile(
  projects: SreeportProjectConfig[],
  options: CaddyOptions = {}
): string {
  const sitePort = options.listenPort && options.listenPort !== 80 ? `:${options.listenPort}` : "";
  const routes = projects
    .filter((project) => project.visible !== false)
    .map(
      (project) => `http://${project.domain}${sitePort} {
\treverse_proxy 127.0.0.1:${project.port}
}`
    )
    .join("\n\n");

  const fallbackMessage = options.fallbackMessage ?? "No Sreeport project configured for this host.";
  return `{
\tadmin off
\tauto_https off
}

${routes}

http://${sitePort} {
\trespond "${escapeCaddyString(fallbackMessage)}" 404
}
`;
}

export function writeCaddyfile(filePath: string, projects: SreeportProjectConfig[], options?: CaddyOptions): string {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const contents = generateCaddyfile(projects, options);
  fs.writeFileSync(filePath, contents);
  return contents;
}

function escapeCaddyString(input: string): string {
  return input.replaceAll("\\", "\\\\").replaceAll('"', '\\"');
}
