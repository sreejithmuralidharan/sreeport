import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import { getRuntimePaths, projectLogPath, projectPidPath } from "./paths.js";
import type { ProjectStatus, RuntimePaths, SreeportProjectConfig, StartResult, StopResult } from "./types.js";

export function isPidAlive(pid?: number): boolean {
  if (!pid) return false;
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

export function readPid(filePath: string): number | undefined {
  try {
    const text = fs.readFileSync(filePath, "utf8").trim();
    return text ? Number(text) : undefined;
  } catch {
    return undefined;
  }
}

export function portListening(port: number): boolean {
  if (process.platform === "win32") {
    const result = spawnSync("netstat", ["-ano"], { encoding: "utf8" });
    return result.stdout.includes(`:${port} `);
  }

  const result = spawnSync("lsof", ["-nP", `-iTCP:${port}`, "-sTCP:LISTEN"], {
    encoding: "utf8"
  });
  return result.status === 0 && result.stdout.split("\n").length > 1;
}

export function projectUrl(project: SreeportProjectConfig): string {
  return `http://${project.domain}`;
}

export function statusForProject(
  project: SreeportProjectConfig,
  runtime: RuntimePaths = getRuntimePaths()
): ProjectStatus {
  const pidPath = projectPidPath(project.name, runtime);
  const pid = readPid(pidPath);
  const running = isPidAlive(pid);
  const listening = portListening(project.port);
  return {
    name: project.name,
    domain: project.domain,
    port: project.port,
    pid: running ? pid : undefined,
    running,
    listening,
    url: projectUrl(project),
    logPath: projectLogPath(project.name, runtime)
  };
}

export function statusForProjects(projects: SreeportProjectConfig[], runtime = getRuntimePaths()): ProjectStatus[] {
  return projects.map((project) => statusForProject(project, runtime));
}

export function startProject(project: SreeportProjectConfig, runtime = getRuntimePaths()): StartResult {
  fs.mkdirSync(runtime.logDir, { recursive: true });
  fs.mkdirSync(runtime.stateDir, { recursive: true });

  const pidPath = projectPidPath(project.name, runtime);
  const currentPid = readPid(pidPath);
  if (isPidAlive(currentPid)) {
    return { project: project.name, started: false, message: "already running", pid: currentPid };
  }

  if (portListening(project.port)) {
    return { project: project.name, started: false, message: `port ${project.port} already has a listener` };
  }

  const command = project.command ?? defaultCommand(project);
  const out = fs.openSync(projectLogPath(project.name, runtime), "a");
  const child = spawn(command, {
    cwd: project.cwd ?? process.cwd(),
    detached: true,
    env: {
      ...process.env,
      ...project.env,
      NEXT_TELEMETRY_DISABLED: "1",
      PORT: String(project.port),
      SREEPORT_DOMAIN: project.domain,
      SREEPORT_PORT: String(project.port)
    },
    shell: true,
    stdio: ["ignore", out, out]
  });
  child.unref();
  fs.writeFileSync(pidPath, String(child.pid));
  return { project: project.name, started: true, message: "started", pid: child.pid };
}

export function stopProject(project: SreeportProjectConfig, runtime = getRuntimePaths()): StopResult {
  const pidPath = projectPidPath(project.name, runtime);
  const pid = readPid(pidPath);
  if (!isPidAlive(pid)) {
    fs.rmSync(pidPath, { force: true });
    return { project: project.name, stopped: false, message: "not running" };
  }

  try {
    if (process.platform !== "win32") process.kill(-pid!, "SIGTERM");
    else process.kill(pid!, "SIGTERM");
  } catch {
    process.kill(pid!, "SIGTERM");
  }
  fs.rmSync(pidPath, { force: true });
  return { project: project.name, stopped: true, message: "stopped" };
}

export function readProjectLog(projectName: string, runtime = getRuntimePaths(), lines = 120): string {
  const filePath = projectLogPath(projectName, runtime);
  try {
    const content = fs.readFileSync(filePath, "utf8");
    return content.split(/\r?\n/).slice(-lines).join("\n");
  } catch {
    return "";
  }
}

function defaultCommand(project: SreeportProjectConfig): string {
  if (project.framework === "next") {
    return `npx next dev -p ${project.port} -H 127.0.0.1`;
  }
  return `npm run dev -- -p ${project.port}`;
}
