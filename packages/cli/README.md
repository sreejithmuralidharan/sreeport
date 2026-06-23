# @sreeport/cli

Command-line interface for Sreeport.

Sreeport gives local development projects stable ports, `.localhost` domains, Caddy routing, browser preferences, logs, and start/stop/restart commands.

## Install

```bash
npm install -g @sreeport/cli
```

## Quick Start

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

## Example Config

```ts
export default {
  projects: [
    {
      name: "web",
      domain: "web.localhost",
      port: 3100,
      framework: "next",
      browser: "chrome"
    }
  ]
} satisfies import("@sreeport/core").SreeportConfig;
```

## Caddy

Sreeport uses Caddy for local routing. Install Caddy separately:

```bash
brew install caddy
```

Then run:

```bash
sreeport proxy start
```

## Privacy

The CLI reads your local `sreeport.config.*` file and writes runtime state under the standard user application support paths. This npm package does not ship private mappings, logs, or environment files.

## Links

- Repository: https://github.com/sreejithmuralidharan/sreeport
- Documentation: https://github.com/sreejithmuralidharan/sreeport#readme
- Issues: https://github.com/sreejithmuralidharan/sreeport/issues

## License

MIT
