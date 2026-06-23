# @sreeport/mcp

Model Context Protocol server for Sreeport.

Sreeport is a local development orchestrator that gives projects stable ports, `.localhost` domains, Caddy routing, browser preferences, logs, and start/stop/restart workflows.

Use `@sreeport/mcp` when an MCP-capable assistant or local tool should inspect and control Sreeport projects through the same core behavior as the CLI.

## What This Package Does

This package starts a stdio MCP server named `sreeport`. MCP clients can use it to:

- list configured projects and current process state
- start, stop, and restart projects
- open project URLs in configured browsers
- read recent project logs
- run Sreeport doctor checks
- inspect and manage the Sreeport Caddy proxy

The server does not create its own project mappings. It reads the `sreeport.config.*` file from the workspace you provide with `--cwd`.

## Install

```bash
npm install -g @sreeport/mcp
```

For day-to-day terminal usage, install the CLI as well:

```bash
npm install -g @sreeport/cli
```

## Client Configuration

Point your MCP client at `sreeport-mcp` and pass the workspace containing `sreeport.config.ts`.

```json
{
  "mcpServers": {
    "sreeport": {
      "command": "sreeport-mcp",
      "args": ["--cwd", "/path/to/workspace"]
    }
  }
}
```

If you use a custom Sreeport runtime directory, include `--config-dir`.

```json
{
  "mcpServers": {
    "sreeport": {
      "command": "sreeport-mcp",
      "args": ["--cwd", "/path/to/workspace", "--config-dir", "/path/to/runtime"]
    }
  }
}
```

## Tools

The server exposes these tools:

| Tool | Description |
| --- | --- |
| `sreeport_status` | Return configured projects, runtime paths, and proxy status. |
| `sreeport_start` | Start one project or all projects. |
| `sreeport_stop` | Stop one project or all projects. |
| `sreeport_restart` | Restart one project or all projects. |
| `sreeport_open` | Open a project URL in its configured browser. |
| `sreeport_logs` | Read recent logs for a project. |
| `sreeport_doctor` | Check local requirements and mappings. |
| `sreeport_proxy` | Run proxy `status`, `write`, `start`, `stop`, or `restart`. |

## Example Prompt

After configuring the MCP server, an MCP-capable assistant can answer prompts such as:

```text
Which Sreeport projects are running?
Restart the web project and show me its latest logs.
Run doctor and tell me what is misconfigured.
```

## Package Map

| Package | Use it for |
| --- | --- |
| `@sreeport/cli` | Daily terminal usage. |
| `@sreeport/core` | Programmatic API and shared engine. |
| `@sreeport/next` | Next.js config helper. |
| `@sreeport/mcp` | MCP server for assistant/tool access. |

## Privacy

The MCP server reads the workspace you point it at with `--cwd`. Only configure it for workspaces you are comfortable exposing to your MCP client. This npm package does not include private mappings, logs, environment files, or runtime state.

## Links

- Repository: https://github.com/sreejithmuralidharan/sreeport
- Documentation: https://github.com/sreejithmuralidharan/sreeport/blob/main/docs/mcp.md
- Issues: https://github.com/sreejithmuralidharan/sreeport/issues

## License

MIT
