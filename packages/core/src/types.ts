export type BrowserChoice =
  | "default"
  | "safari"
  | "chrome"
  | "arc"
  | "firefox"
  | `bundle:${string}`
  | `app:${string}`;

export type Framework = "next" | "vite" | "custom";

export interface SreeportProjectConfig {
  name: string;
  domain: string;
  port: number;
  command?: string;
  cwd?: string;
  browser?: BrowserChoice;
  framework?: Framework;
  env?: Record<string, string>;
  visible?: boolean;
}

export interface SreeportConfig {
  projects: SreeportProjectConfig[];
}

export interface RuntimePaths {
  configDir: string;
  dataDir: string;
  logDir: string;
  stateDir: string;
  caddyfile: string;
}

export interface ProjectStatus {
  name: string;
  domain: string;
  port: number;
  pid?: number;
  running: boolean;
  listening: boolean;
  url: string;
  logPath: string;
}

export interface StartResult {
  project: string;
  started: boolean;
  message: string;
  pid?: number;
}

export interface StopResult {
  project: string;
  stopped: boolean;
  message: string;
}

export interface DoctorCheck {
  name: string;
  ok: boolean;
  message: string;
}
