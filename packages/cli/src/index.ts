#!/usr/bin/env node
import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { pathToFileURL } from "node:url";
import { Command } from "commander";
import {
  configTemplate,
  findProjectConfig,
  generateCaddyfile,
  getRuntimePaths,
  loadProjectConfig,
  openUrl,
  projectPidPath,
  readProjectLog,
  runDoctor,
  scanProjects,
  startProject,
  statusForProjects,
  stopProject,
  validateProjects,
  writeCaddyfile
} from "@sreeport/core";
import type { RuntimePaths, SreeportConfig, SreeportProjectConfig } from "@sreeport/core";

const program = new Command();

program
  .name("sreeport")
  .description("Launch local dev projects with stable ports, local domains, and browser routing.")
  .version("0.1.2")
  .option("--config-dir <path>", "Use an alternate Sreeport runtime directory for state/config/logs");

program
  .command("init")
  .description("Create a project-local sreeport.config.ts")
  .option("--name <name>", "Project name")
  .option("--domain <domain>", "Local domain")
  .option("--port <port>", "Local port", "3100")
  .action((options) => {
    const cwd = process.cwd();
    const name = options.name ?? safeName(path.basename(cwd));
    const domain = options.domain ?? `${name}.localhost`;
    const port = Number(options.port);
    const target = path.join(cwd, "sreeport.config.ts");
    if (fs.existsSync(target)) exitWithError("sreeport.config.ts already exists");
    fs.writeFileSync(target, configTemplate(name, domain, port));
    console.log(`Created ${target}`);
  });

program
  .command("scan")
  .description("Scan a folder for package.json projects and suggest mappings")
  .argument("[root]", "Root folder to scan", process.cwd())
  .option("--json", "Print JSON")
  .option("--start-port <port>", "First suggested port", "3100")
  .action((root, options) => {
    const projects = scanProjects({ root, startPort: Number(options.startPort) });
    if (options.json) {
      console.log(JSON.stringify({ projects }, null, 2));
      return;
    }
    for (const project of projects) {
      console.log(`${project.name}\t${project.domain}\t${project.port}\t${project.cwd}`);
    }
  });

program
  .command("status")
  .description("Show configured project status")
  .option("--json", "Print JSON")
  .action(async (options) => {
    const runtime = runtimePaths();
    const config = await loadConfig();
    const statuses = statusForProjects(config.projects, runtime);
    if (options.json) {
      console.log(JSON.stringify({ projects: statuses, runtime }, null, 2));
      return;
    }
    console.log(`Config: ${findProjectConfig() ?? "none"}`);
    for (const status of statuses) {
      console.log(
        `${status.name.padEnd(18)} ${status.running ? `pid=${String(status.pid).padEnd(7)}` : "stopped".padEnd(11)} ${String(status.port).padEnd(5)} ${status.listening ? "listening" : "not-listening"} ${status.url}`
      );
    }
  });

program
  .command("start")
  .description("Start one project or all projects")
  .argument("[project]", "Project name or all", "all")
  .action(async (name) => {
    const { projects } = await selectedProjects(name);
    const runtime = runtimePaths();
    for (const project of projects) {
      const result = startProject(project, runtime);
      console.log(`${project.name}: ${result.message}${result.pid ? ` pid=${result.pid}` : ""}`);
    }
  });

program
  .command("stop")
  .description("Stop one project or all projects")
  .argument("[project]", "Project name or all", "all")
  .action(async (name) => {
    const { projects } = await selectedProjects(name);
    const runtime = runtimePaths();
    for (const project of projects) {
      const result = stopProject(project, runtime);
      console.log(`${project.name}: ${result.message}`);
    }
  });

program
  .command("restart")
  .description("Restart one project or all projects")
  .argument("[project]", "Project name or all", "all")
  .action(async (name) => {
    const { projects } = await selectedProjects(name);
    const runtime = runtimePaths();
    for (const project of projects) {
      stopProject(project, runtime);
      const result = startProject(project, runtime);
      console.log(`${project.name}: ${result.message}${result.pid ? ` pid=${result.pid}` : ""}`);
    }
  });

program
  .command("open")
  .description("Open a project URL in its configured browser")
  .argument("[project]", "Project name")
  .action(async (name) => {
    const config = await loadConfig();
    const project = findProject(config.projects, name);
    await openUrl(`http://${project.domain}`, project.browser);
    console.log(`Opened http://${project.domain}`);
  });

program
  .command("logs")
  .description("Print recent project logs")
  .argument("[project]", "Project name")
  .option("--lines <lines>", "Number of lines", "120")
  .action(async (name, options) => {
    const config = await loadConfig();
    const project = findProject(config.projects, name);
    console.log(readProjectLog(project.name, runtimePaths(), Number(options.lines)));
  });

program
  .command("doctor")
  .description("Check local Sreeport requirements and project mappings")
  .action(async () => {
    const config = await loadConfig();
    const checks = runDoctor(config.projects);
    for (const check of checks) {
      console.log(`${check.ok ? "ok" : "fail"} ${check.name}: ${check.message}`);
    }
    process.exitCode = checks.every((check) => check.ok) ? 0 : 1;
  });

const proxy = program.command("proxy").description("Manage the Caddy proxy");

proxy
  .command("status")
  .description("Show Sreeport-managed Caddy status")
  .option("--json", "Print JSON")
  .action((options) => {
    const runtime = runtimePaths();
    const pidPath = projectPidPath("caddy", runtime);
    const pid = readOptionalPid(pidPath);
    const running = Boolean(pid && isAlive(pid));
    const status = {
      running,
      pid: running ? pid : undefined,
      caddyfile: runtime.caddyfile
    };
    if (options.json) {
      console.log(JSON.stringify(status, null, 2));
      return;
    }
    console.log(`caddy ${running ? `running pid=${pid}` : "stopped"} config=${runtime.caddyfile}`);
  });

proxy
  .command("write")
  .description("Write the Sreeport Caddyfile")
  .action(async () => {
    const runtime = runtimePaths();
    const config = await loadConfig();
    assertValid(config.projects);
    const contents = writeCaddyfile(runtime.caddyfile, config.projects);
    console.log(runtime.caddyfile);
    console.log(contents);
  });

proxy
  .command("start")
  .description("Start Caddy with the generated Sreeport config")
  .action(async () => {
    const runtime = runtimePaths();
    const config = await loadConfig();
    assertValid(config.projects);
    writeCaddyfile(runtime.caddyfile, config.projects);
    startCaddy(runtime);
  });

proxy
  .command("stop")
  .description("Stop the Sreeport-managed Caddy process")
  .action(() => stopCaddy(runtimePaths()));

proxy
  .command("restart")
  .description("Restart the Sreeport-managed Caddy process")
  .action(async () => {
    const runtime = runtimePaths();
    stopCaddy(runtime);
    const config = await loadConfig();
    assertValid(config.projects);
    writeCaddyfile(runtime.caddyfile, config.projects);
    startCaddy(runtime);
  });

const next = program.command("next").description("Next.js helpers");

next
  .command("init")
  .description("Create a Next.js-friendly Sreeport config")
  .option("--name <name>", "Project name")
  .option("--domain <domain>", "Local domain")
  .option("--port <port>", "Local port", "3100")
  .action((options) => {
    const cwd = process.cwd();
    const name = options.name ?? safeName(path.basename(cwd));
    const domain = options.domain ?? `${name}.localhost`;
    const port = Number(options.port);
    const target = path.join(cwd, "sreeport.config.ts");
    if (fs.existsSync(target)) exitWithError("sreeport.config.ts already exists");
    fs.writeFileSync(target, configTemplate(name, domain, port));
    console.log(`Created ${target}`);
    console.log("Add withSreeportNextConfig from @sreeport/next to next.config when you want allowedDevOrigins synced.");
  });

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
  program.parseAsync(process.argv).catch((error) => {
    exitWithError(error instanceof Error ? error.message : String(error));
  });
}

async function loadConfig(): Promise<SreeportConfig> {
  const config = await loadProjectConfig(process.cwd());
  if (config.projects.length === 0) {
    exitWithError("No Sreeport projects found. Run `sreeport init` or create sreeport.config.ts.");
  }
  return config;
}

async function selectedProjects(name: string): Promise<{ projects: SreeportProjectConfig[] }> {
  const config = await loadConfig();
  if (name === "all") return { projects: config.projects };
  return { projects: [findProject(config.projects, name)] };
}

function findProject(projects: SreeportProjectConfig[], name?: string): SreeportProjectConfig {
  if (!name && projects.length === 1) return projects[0]!;
  if (!name) exitWithError("Project name is required when multiple projects are configured.");
  const project = projects.find((candidate) => candidate.name === name);
  if (!project) exitWithError(`Unknown project: ${name}`);
  return project;
}

function assertValid(projects: SreeportProjectConfig[]): void {
  const errors = validateProjects(projects);
  if (errors.length) exitWithError(errors.join("\n"));
}

function runtimePaths(): RuntimePaths {
  const options = program.opts<{ configDir?: string }>();
  return getRuntimePaths(options.configDir);
}

function startCaddy(runtime: RuntimePaths): void {
  fs.mkdirSync(runtime.stateDir, { recursive: true });
  fs.mkdirSync(runtime.logDir, { recursive: true });
  const pidPath = projectPidPath("caddy", runtime);
  const existing = readOptionalPid(pidPath);
  if (existing && isAlive(existing)) {
    console.log(`caddy: already running pid=${existing}`);
    return;
  }
  const validation = spawnSync("caddy", ["validate", "--config", runtime.caddyfile], { encoding: "utf8" });
  if (validation.status !== 0) exitWithError(validation.stderr || validation.stdout || "Caddy validation failed");
  const log = fs.openSync(path.join(runtime.logDir, "caddy.log"), "a");
  const child = spawn("caddy", ["run", "--config", runtime.caddyfile, "--pidfile", pidPath], {
    detached: true,
    stdio: ["ignore", log, log]
  });
  child.unref();
  fs.writeFileSync(pidPath, String(child.pid));
  console.log(`caddy: started pid=${child.pid}`);
}

function stopCaddy(runtime: RuntimePaths): void {
  const pidPath = projectPidPath("caddy", runtime);
  const pid = readOptionalPid(pidPath);
  if (!pid || !isAlive(pid)) {
    fs.rmSync(pidPath, { force: true });
    console.log("caddy: stopped");
    return;
  }
  try {
    if (process.platform !== "win32") process.kill(-pid, "SIGTERM");
    else process.kill(pid, "SIGTERM");
  } catch {
    process.kill(pid, "SIGTERM");
  }
  fs.rmSync(pidPath, { force: true });
  console.log(`caddy: stopping pid=${pid}`);
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

function safeName(input: string): string {
  return input.toLowerCase().replace(/[^a-z0-9._-]+/g, "-").replace(/^-+|-+$/g, "");
}

function exitWithError(message: string): never {
  console.error(message);
  process.exit(1);
}

export { generateCaddyfile };
