import type { SreeportProjectConfig } from "./types.js";

export function validateProjects(projects: SreeportProjectConfig[]): string[] {
  const errors: string[] = [];
  const names = new Map<string, string>();
  const domains = new Map<string, string>();
  const ports = new Map<number, string>();

  for (const project of projects) {
    collectDuplicate(errors, names, project.name, project.name, "name");
    collectDuplicate(errors, domains, project.domain, project.name, "domain");
    collectDuplicate(errors, ports, project.port, project.name, "port");

    if (!project.domain.endsWith(".localhost")) {
      errors.push(`${project.name}: domain should end with .localhost for zero-setup local DNS`);
    }
  }

  return errors;
}

function collectDuplicate<T>(
  errors: string[],
  seen: Map<T, string>,
  key: T,
  projectName: string,
  label: string
): void {
  const existing = seen.get(key);
  if (existing) {
    errors.push(`${projectName}: duplicate ${label} also used by ${existing}`);
    return;
  }
  seen.set(key, projectName);
}
