import envPaths from "env-paths";
import path from "node:path";
import type { RuntimePaths } from "./types.js";

export function getRuntimePaths(baseDir?: string): RuntimePaths {
  const paths = baseDir
    ? {
        config: path.join(baseDir, "config"),
        data: path.join(baseDir, "data"),
        log: path.join(baseDir, "logs")
      }
    : envPaths("Sreeport", { suffix: "" });

  const stateDir = path.join(paths.data, "state");
  return {
    configDir: paths.config,
    dataDir: paths.data,
    logDir: paths.log,
    stateDir,
    caddyfile: path.join(paths.config, "Caddyfile")
  };
}

export function projectLogPath(projectName: string, runtime = getRuntimePaths()): string {
  return path.join(runtime.logDir, `${projectName}.log`);
}

export function projectPidPath(projectName: string, runtime = getRuntimePaths()): string {
  return path.join(runtime.stateDir, `${projectName}.pid`);
}
