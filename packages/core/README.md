# @sreeport/core

Core engine for Sreeport, a local development orchestrator for teams and developers who run many apps at the same time.

Sreeport gives each local project a stable port, a clean `.localhost` domain, browser preferences, logs, process status, and start/stop/restart workflows. It is designed to make parallel Next.js and full-stack development less chaotic without requiring Docker or a heavy platform.

## Which Package Should I Install?

Most users should start with the CLI:

```bash
npm install -g @sreeport/cli
```

Install `@sreeport/core` only when you are building another tool, app, script, or integration on top of Sreeport.

| Package | Use it for |
| --- | --- |
| `@sreeport/cli` | Daily terminal usage: start, stop, restart, status, logs, proxy. |
| `@sreeport/core` | Programmatic config loading, validation, process management, Caddy generation. |
| `@sreeport/next` | Next.js config helpers for Sreeport dev origins. |
| `@sreeport/mcp` | MCP server for assistant/tool integration. |

## Install

```bash
npm install @sreeport/core
```

## What This Package Does

`@sreeport/core` contains the reusable logic used by the CLI, MCP server, and macOS app:

- load and normalize `sreeport.config.ts`
- validate duplicate project names, domains, and ports
- generate Sreeport-owned Caddy config
- inspect process and port state
- start and stop configured projects
- read project logs
- resolve browser launch commands
- scan folders for candidate projects
- provide runtime paths for state, logs, and proxy config

It does not provide a command-line binary. Use `@sreeport/cli` for that.

## Example: Define Config

```ts
import {
  defineSreeportConfig,
  generateCaddyfile,
  statusForProjects,
  validateProjects
} from "@sreeport/core";

const config = defineSreeportConfig({
  projects: [
    {
      name: "web",
      domain: "web.localhost",
      port: 3100,
      framework: "next",
      browser: "default"
    }
  ]
});

const errors = validateProjects(config.projects);
if (errors.length > 0) {
  throw new Error(errors.join("\n"));
}

console.log(statusForProjects(config.projects));
console.log(generateCaddyfile(config.projects));
```

## Example: Project Config File

Sreeport reads project-local config from `sreeport.config.ts`, `sreeport.config.js`, or `sreeport.config.json`.

```ts
import { defineSreeportConfig } from "@sreeport/core";

export default defineSreeportConfig({
  projects: [
    {
      name: "api",
      domain: "api.localhost",
      port: 3101,
      command: "npm run dev",
      framework: "custom",
      browser: "default"
    }
  ]
});
```

## Public API

- `defineSreeportConfig`
- `loadProjectConfig`
- `validateProjects`
- `statusForProjects`
- `startProject`
- `stopProject`
- `readProjectLog`
- `runDoctor`
- `generateCaddyfile`
- `writeCaddyfile`
- `openUrl`
- `scanProjects`
- `getRuntimePaths`

## Caddy Integration

The core package can generate the Caddyfile used by Sreeport:

```caddyfile
http://web.localhost {
  reverse_proxy 127.0.0.1:3100
}

http:// {
  respond "No Sreeport project configured for this host." 404
}
```

The CLI handles writing and running this config with `sreeport proxy start`.

## Privacy

This package does not include private project mappings, logs, environment files, or machine state. It only ships reusable TypeScript/JavaScript implementation code.

Your local mappings stay in your own `sreeport.config.*` files.

## Links

- Repository: https://github.com/sreejithmuralidharan/sreeport
- Documentation: https://github.com/sreejithmuralidharan/sreeport#readme
- Issues: https://github.com/sreejithmuralidharan/sreeport/issues

## License

MIT
