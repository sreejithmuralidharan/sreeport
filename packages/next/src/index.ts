import type { SreeportProjectConfig } from "@sreeport/core";

export interface NextConfigLike {
  allowedDevOrigins?: string[];
  [key: string]: unknown;
}

export interface SreeportNextOptions {
  project: Pick<SreeportProjectConfig, "domain" | "port">;
}

export function withSreeportNextConfig<TConfig extends NextConfigLike>(
  config: TConfig,
  options: SreeportNextOptions
): TConfig {
  const origin = `http://${options.project.domain}`;
  const localhost = `http://127.0.0.1:${options.project.port}`;
  const allowedDevOrigins = Array.from(
    new Set([...(config.allowedDevOrigins ?? []), origin, localhost])
  );
  return {
    ...config,
    allowedDevOrigins
  };
}

export function nextDevCommand(project: Pick<SreeportProjectConfig, "port">): string {
  return `next dev -p ${project.port} -H 127.0.0.1`;
}

export function nextPackageScript(project: Pick<SreeportProjectConfig, "port">): string {
  return `sreeport start && next dev -p ${project.port} -H 127.0.0.1`;
}
