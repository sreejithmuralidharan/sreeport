# @sreeport/next

Next.js integration helpers for Sreeport.

Sreeport is a local development orchestrator that gives projects stable ports, `.localhost` domains, Caddy routing, browser preferences, logs, and start/stop/restart workflows.

Use `@sreeport/next` when a Next.js project needs to understand the same local domain and port that Sreeport uses to launch it.

## Which Package Should I Install?

For day-to-day Sreeport usage, install the CLI:

```bash
npm install -g @sreeport/cli
```

Install this package inside a Next.js app when you want a `next.config` helper.

## Install

```bash
npm install -D @sreeport/next
```

## What This Package Does

`@sreeport/next` provides `withSreeportNextConfig`, a small helper that adds Sreeport dev origins to Next.js config.

That helps when your dev app is reached through a local domain such as:

```text
http://web.localhost
```

while the underlying Next.js server is listening on:

```text
http://127.0.0.1:3100
```

## Usage

```ts
import { withSreeportNextConfig } from "@sreeport/next";

const nextConfig = withSreeportNextConfig(
  {},
  {
    project: {
      domain: "web.localhost",
      port: 3100
    }
  }
);

export default nextConfig;
```

The helper adds local development origins for the configured domain and loopback port.

## Sreeport Project Config

Create a project config with the CLI:

```bash
sreeport next init --name web --domain web.localhost --port 3100
```

Or write one manually:

```ts
export default {
  projects: [
    {
      name: "web",
      domain: "web.localhost",
      port: 3100,
      framework: "next",
      browser: "default"
    }
  ]
} satisfies import("@sreeport/core").SreeportConfig;
```

## Dev Command

Sreeport starts Next.js with an explicit host and port:

```bash
next dev -p 3100 -H 127.0.0.1
```

If your app needs setup before Next starts, add a custom `command` in `sreeport.config.ts`.

```ts
command: "prisma generate && next dev -p 3100 -H 127.0.0.1"
```

## Package Map

| Package | Use it for |
| --- | --- |
| `@sreeport/cli` | Daily terminal usage. |
| `@sreeport/core` | Programmatic API and shared engine. |
| `@sreeport/next` | Next.js config helper. |
| `@sreeport/mcp` | MCP server for assistant/tool access. |

## Privacy

This package only ships the Next.js helper. It does not include private project mappings, logs, environment files, or runtime state.

## Links

- Repository: https://github.com/sreejithmuralidharan/sreeport
- Documentation: https://github.com/sreejithmuralidharan/sreeport/blob/main/docs/next.md
- Issues: https://github.com/sreejithmuralidharan/sreeport/issues

## License

MIT
