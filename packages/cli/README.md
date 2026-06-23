# @sreeport/cli

Command-line interface for Sreeport, a local development orchestrator for people who run many projects at once.

Sreeport gives each app a stable port, a clean `.localhost` domain, a browser preference, logs, health state, and predictable start/stop/restart commands. It is especially useful when you have multiple Next.js or full-stack projects running in parallel and port management has become hard to reason about.

## What You Get

- stable local domains such as `web.localhost` and `api.localhost`
- explicit ports instead of random fallback ports
- Caddy-powered reverse proxy config
- start, stop, restart, open, status, and logs commands
- per-project browser routing
- project-local `sreeport.config.ts`
- cross-platform core with a macOS menu-bar app available in the repo

## Install

```bash
npm install -g @sreeport/cli
```

## Quick Start: One Project

Create a Sreeport config in a project:

```bash
sreeport next init --name web --domain web.localhost --port 3100
```

Start the project:

```bash
sreeport start web
```

Start the local proxy:

```bash
sreeport proxy start
```

Open the project:

```bash
sreeport open web
```

Check health and logs:

```bash
sreeport status
sreeport logs web
sreeport doctor
```

## Quick Start: Multiple Projects

Create a workspace-level `sreeport.config.ts` with several projects:

```ts
export default {
  projects: [
    {
      name: "web",
      domain: "web.localhost",
      port: 3100,
      cwd: "../web",
      framework: "next",
      browser: "chrome"
    },
    {
      name: "api",
      domain: "api.localhost",
      port: 3101,
      cwd: "../api",
      command: "npm run dev",
      framework: "custom"
    }
  ]
} satisfies import("@sreeport/core").SreeportConfig;
```

Then run everything:

```bash
sreeport start all
sreeport proxy restart
sreeport status
```

## Commands

```bash
sreeport init
sreeport scan
sreeport start [project|all]
sreeport stop [project|all]
sreeport restart [project|all]
sreeport open [project]
sreeport status --json
sreeport logs [project]
sreeport proxy status|write|start|stop|restart
sreeport doctor
sreeport next init
```

## Config Fields

| Field | Description |
| --- | --- |
| `name` | Stable project id used by CLI commands. |
| `domain` | Local domain, usually ending in `.localhost`. |
| `port` | Port the app should listen on. |
| `cwd` | Working directory for the command. Defaults to the config directory. |
| `command` | Optional custom dev command. |
| `framework` | `next`, `vite`, or `custom`. |
| `browser` | `default`, `safari`, `chrome`, `arc`, `firefox`, `bundle:*`, or `app:*`. |
| `env` | Extra environment variables for the dev process. |
| `visible` | Hide a project from UI while keeping it configured. |

## Caddy

Sreeport uses Caddy for local routing. Install Caddy separately:

```bash
brew install caddy
```

Then run:

```bash
sreeport proxy start
```

Sreeport writes its own generated Caddyfile and adds a fallback `404` for unmapped hosts.

## Package Map

| Package | Use it for |
| --- | --- |
| `@sreeport/cli` | Daily terminal usage. |
| `@sreeport/core` | Programmatic API and shared engine. |
| `@sreeport/next` | Next.js config helper. |
| `@sreeport/mcp` | MCP server for assistant/tool access. |

## Privacy

The CLI reads your local `sreeport.config.*` file and writes runtime state under the standard user application support paths. This npm package does not ship private mappings, logs, or environment files.

## Links

- Repository: https://github.com/sreejithmuralidharan/sreeport
- Documentation: https://github.com/sreejithmuralidharan/sreeport#readme
- Issues: https://github.com/sreejithmuralidharan/sreeport/issues

## License

MIT
