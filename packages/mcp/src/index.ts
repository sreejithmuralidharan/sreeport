#!/usr/bin/env node
import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import {
  getRuntimePaths,
  loadProjectConfig,
  openUrl,
  projectPidPath,
  readProjectLog,
  runDoctor,
  startProject,
  statusForProjects,
  stopProject,
  validateProjects,
  writeCaddyfile
} from "@sreeport/core";
import type { RuntimePaths, SreeportConfig, SreeportProjectConfig } from "@sreeport/core";

interface ServerOptions {
  cwd: string;
  configDir?: string;
}

const options = parseArgs(process.argv.slice(2));
const server = new McpServer({
  name: "sreeport",
  version: "0.1.1"
});

server.registerTool(
  "sreeport_status",
  {
    title: "Sreeport Status",
    description: "Return configured Sreeport projects and runtime status.",
    inputSchema: {}
  },
  async () => textResult(await statusText())
);

server.registerTool(
  "sreeport_start",
  {
    title: "Start Sreeport Project",
    description: "Start one configured project, or all projects when project is omitted.",
    inputSchema: {
      project: z.string().optional().describe("Project name, or omit to start all projects.")
    }
  },
  async ({ project }) => textResult(await projectAction(project, "start"))
);

server.registerTool(
  "sreeport_stop",
  {
    title: "Stop Sreeport Project",
    description: "Stop one configured project, or all projects when project is omitted.",
    inputSchema: {
      project: z.string().optional().describe("Project name, or omit to stop all projects.")
    }
  },
  async ({ project }) => textResult(await projectAction(project, "stop"))
);

server.registerTool(
  "sreeport_restart",
  {
    title: "Restart Sreeport Project",
    description: "Restart one configured project, or all projects when project is omitted.",
    inputSchema: {
      project: z.string().optional().describe("Project name, or omit to restart all projects.")
    }
  },
  async ({ project }) => textResult(await projectAction(project, "restart"))
);

server.registerTool(
  "sreeport_open",
  {
    title: "Open Sreeport Project",
    description: "Open a configured project in its configured browser.",
    inputSchema: {
      project: z.string().describe("Project name.")
    }
  },
  async ({ project }) => {
    const config = await loadConfig();
    const selected = findProject(config.projects, project);
    const url = `http://${selected.domain}`;
    await openUrl(url, selected.browser);
    return textResult(`Opened ${url}`);
  }
);

server.registerTool(
  "sreeport_logs",
  {
    title: "Read Sreeport Logs",
    description: "Read recent logs for a configured project.",
    inputSchema: {
      project: z.string().describe("Project name."),
      lines: z.number().int().min(1).max(1000).default(120).describe("Number of recent lines to return.")
    }
  },
  async ({ project, lines }) => {
    const config = await loadConfig();
    const selected = findProject(config.projects, project);
    const logs = readProjectLog(selected.name, runtimePaths(), lines);
    return textResult(logs.trim() || `No log output yet for ${selected.name}.`);
  }
);

server.registerTool(
  "sreeport_doctor",
  {
    title: "Run Sreeport Doctor",
    description: "Check Sreeport requirements and project mappings.",
    inputSchema: {}
  },
  async () => {
    const config = await loadConfig();
    const checks = runDoctor(config.projects);
    return textResult(checks.map((check) => `${check.ok ? "ok" : "fail"} ${check.name}: ${check.message}`).join("\n"));
  }
);

server.registerTool(
  "sreeport_proxy",
  {
    title: "Manage Sreeport Proxy",
    description: "Inspect or manage the Sreeport-owned Caddy proxy.",
    inputSchema: {
      action: z.enum(["status", "write", "start", "stop", "restart"]).default("status")
    }
  },
  async ({ action }) => textResult(await proxyAction(action))
);

await server.connect(new StdioServerTransport());

function parseArgs(args: string[]): ServerOptions {
  let cwd = process.cwd();
  let configDir: string | undefined;

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if (arg === "--cwd") {
      cwd = path.resolve(requiredValue(args, index));
      index += 1;
      continue;
    }
    if (arg === "--config-dir") {
      configDir = path.resolve(requiredValue(args, index));
      index += 1;
      continue;
    }
    if (arg === "--help" || arg === "-h") {
      process.stderr.write("Usage: sreeport-mcp [--cwd <workspace>] [--config-dir <runtime-dir>]\n");
      process.exit(0);
    }
    throw new Error(`Unknown argument: ${arg}`);
  }

  return { cwd, configDir };
}

function requiredValue(args: string[], index: number): string {
  const value = args[index + 1];
  if (!value) throw new Error(`Missing value for ${args[index]}`);
  return value;
}

async function loadConfig(): Promise<SreeportConfig> {
  const config = await loadProjectConfig(options.cwd);
  if (config.projects.length === 0) {
    throw new Error("No Sreeport projects found. Run `sreeport init` or create sreeport.config.ts.");
  }
  return config;
}

function runtimePaths(): RuntimePaths {
  return getRuntimePaths(options.configDir);
}

async function statusText(): Promise<string> {
  const config = await loadConfig();
  const runtime = runtimePaths();
  const statuses = statusForProjects(config.projects, runtime);
  return JSON.stringify({ projects: statuses, runtime, proxy: proxyStatus(runtime) }, null, 2);
}

async function projectAction(projectName: string | undefined, action: "start" | "stop" | "restart"): Promise<string> {
  const config = await loadConfig();
  const runtime = runtimePaths();
  const selected = selectProjects(config.projects, projectName);
  const output: string[] = [];

  for (const project of selected) {
    if (action === "start") {
      const result = startProject(project, runtime);
      output.push(`${project.name}: ${result.message}${result.pid ? ` pid=${result.pid}` : ""}`);
    }
    if (action === "stop") {
      const result = stopProject(project, runtime);
      output.push(`${project.name}: ${result.message}`);
    }
    if (action === "restart") {
      stopProject(project, runtime);
      const result = startProject(project, runtime);
      output.push(`${project.name}: ${result.message}${result.pid ? ` pid=${result.pid}` : ""}`);
    }
  }

  return output.join("\n");
}

async function proxyAction(action: "status" | "write" | "start" | "stop" | "restart"): Promise<string> {
  const runtime = runtimePaths();
  if (action === "status") {
    const status = proxyStatus(runtime);
    return `caddy ${status.running ? `running pid=${status.pid}` : "stopped"} config=${status.caddyfile}`;
  }

  if (action === "stop") {
    return stopCaddy(runtime);
  }

  const config = await loadConfig();
  const errors = validateProjects(config.projects);
  if (errors.length > 0) throw new Error(errors.join("\n"));
  const contents = writeCaddyfile(runtime.caddyfile, config.projects);

  if (action === "write") {
    return `${runtime.caddyfile}\n${contents}`;
  }

  if (action === "restart") {
    const stopped = stopCaddy(runtime);
    const started = startCaddy(runtime);
    return `${stopped}\n${started}`;
  }

  return startCaddy(runtime);
}

function selectProjects(projects: SreeportProjectConfig[], name?: string): SreeportProjectConfig[] {
  if (!name || name === "all") return projects;
  return [findProject(projects, name)];
}

function findProject(projects: SreeportProjectConfig[], name?: string): SreeportProjectConfig {
  if (!name && projects.length === 1) return projects[0]!;
  if (!name) throw new Error("Project name is required when multiple projects are configured.");
  const project = projects.find((candidate) => candidate.name === name);
  if (!project) throw new Error(`Unknown project: ${name}`);
  return project;
}

function proxyStatus(runtime: RuntimePaths): { running: boolean; pid?: number; caddyfile: string } {
  const pid = readOptionalPid(projectPidPath("caddy", runtime));
  const running = Boolean(pid && isAlive(pid));
  return {
    running,
    pid: running ? pid : undefined,
    caddyfile: runtime.caddyfile
  };
}

function startCaddy(runtime: RuntimePaths): string {
  fs.mkdirSync(runtime.stateDir, { recursive: true });
  fs.mkdirSync(runtime.logDir, { recursive: true });
  const pidPath = projectPidPath("caddy", runtime);
  const existing = readOptionalPid(pidPath);
  if (existing && isAlive(existing)) {
    return `caddy: already running pid=${existing}`;
  }

  const validation = spawnSync("caddy", ["validate", "--config", runtime.caddyfile], { encoding: "utf8" });
  if (validation.status !== 0) throw new Error(validation.stderr || validation.stdout || "Caddy validation failed");

  const log = fs.openSync(path.join(runtime.logDir, "caddy.log"), "a");
  const child = spawn("caddy", ["run", "--config", runtime.caddyfile, "--pidfile", pidPath], {
    detached: true,
    stdio: ["ignore", log, log]
  });
  child.unref();
  fs.writeFileSync(pidPath, String(child.pid));
  return `caddy: started pid=${child.pid}`;
}

function stopCaddy(runtime: RuntimePaths): string {
  const pidPath = projectPidPath("caddy", runtime);
  const pid = readOptionalPid(pidPath);
  if (!pid || !isAlive(pid)) {
    fs.rmSync(pidPath, { force: true });
    return "caddy: stopped";
  }
  try {
    if (process.platform !== "win32") process.kill(-pid, "SIGTERM");
    else process.kill(pid, "SIGTERM");
  } catch {
    process.kill(pid, "SIGTERM");
  }
  fs.rmSync(pidPath, { force: true });
  return `caddy: stopping pid=${pid}`;
}

function readOptionalPid(filePath: string): number | undefined {
  try {
    const text = fs.readFileSync(filePath, "utf8").trim();
    return text ? Number(text) : undefined;
  } catch {
    return undefined;
  }
}

function isAlive(pid: number): boolean {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function textResult(text: string): { content: Array<{ type: "text"; text: string }> } {
  return {
    content: [
      {
        type: "text",
        text
      }
    ]
  };
}
