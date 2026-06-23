import { spawnSync } from "node:child_process";
import fs from "node:fs";
import type { DoctorCheck, SreeportProjectConfig } from "./types.js";
import { validateProjects } from "./validation.js";

export function runDoctor(projects: SreeportProjectConfig[]): DoctorCheck[] {
  const checks: DoctorCheck[] = [];
  checks.push(commandCheck("node", ["--version"], "Node.js is available"));
  checks.push(commandCheck("caddy", ["version"], "Caddy is available"));

  const validation = validateProjects(projects);
  checks.push({
    name: "config",
    ok: validation.length === 0,
    message: validation.length === 0 ? "Project mappings are valid" : validation.join("; ")
  });

  for (const project of projects) {
    checks.push({
      name: `project:${project.name}`,
      ok: Boolean(project.cwd && fs.existsSync(project.cwd)),
      message: project.cwd ? `${project.cwd}` : "Project cwd is missing"
    });
  }

  return checks;
}

function commandCheck(command: string, args: string[], okMessage: string): DoctorCheck {
  const result = spawnSync(command, args, { encoding: "utf8" });
  return {
    name: command,
    ok: result.status === 0,
    message: result.status === 0 ? okMessage : `${command} is not available`
  };
}
