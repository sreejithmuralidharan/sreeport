# Sreeport

![Sreeport harbor-route mark](assets/sreeport-mark.svg)

Sreeport is a local development orchestrator for people who run many apps at once. It gives every project a stable port, clean `.localhost` domain, browser preference, logs, health state, and start/stop/restart workflow.

The product shape is simple:

- a cross-platform core and CLI
- framework integrations, starting with Next.js
- a native macOS menu-bar app for daily control
- Caddy-powered local routing
- plain, portable project config

Sreeport is designed to be useful without becoming a heavy container platform or a full devops dashboard.

## Status

Sreeport is currently `0.1.0` and under active development. The CLI/core are the stable foundation; the macOS app is a native shell scaffold that will grow into the primary UI.

## Quick Start

Install the CLI:

```bash
npm install -g @sreeport/cli
```

Create a config in a project:

```bash
sreeport next init --name web --domain web.localhost --port 3100
```

Start the project:

```bash
sreeport start
```

Write and start the local proxy:

```bash
sreeport proxy start
```

Open the project in its configured browser:

```bash
sreeport open web
```

Check health:

```bash
sreeport status
sreeport doctor
```

## Example Config

```ts
import { defineSreeportConfig } from "@sreeport/core";

export default defineSreeportConfig({
  projects: [
    {
      name: "web",
      domain: "web.localhost",
      port: 3100,
      framework: "next",
      browser: "chrome"
    }
  ]
});
```

## Browser Routing

Each project can choose its browser:

- `default`
- `safari`
- `chrome`
- `arc`
- `firefox`
- `bundle:com.example.Browser`
- `app:/Applications/Browser.app`

On macOS, Sreeport uses LaunchServices through the system `open` command.

## Caddy

Sreeport generates a dedicated Caddyfile with one route per project and a fallback `404` for unmapped hosts.

```caddyfile
http://web.localhost {
  reverse_proxy 127.0.0.1:3100
}

http:// {
  respond "No Sreeport project configured for this host." 404
}
```

Install Caddy separately:

```bash
brew install caddy
```

## Next.js

Install the helper:

```bash
npm install -D @sreeport/next
```

Use it from `next.config.ts`:

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

Sreeport starts Next.js with an explicit port and hostname:

```bash
next dev -p 3100 -H 127.0.0.1
```

## macOS Menu-Bar App

The native macOS app lives in `apps/mac`.

```bash
pnpm --filter @sreeport/mac build
```

The app reads CLI status and dispatches CLI actions, so the same behavior is available in Terminal and in the menu bar.

## Development

```bash
pnpm install
pnpm typecheck
pnpm test
pnpm build
```

Dry-run npm packages:

```bash
pnpm pack:dry
```

## Principles

- No personal project mappings in the repository.
- No telemetry by default.
- Plain config over opaque state.
- Mac-first UI, cross-platform core.
- Ports are part of a project workflow, not the whole product.

## License

MIT © Sreejith Muralidharan
