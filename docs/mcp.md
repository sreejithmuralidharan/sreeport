# MCP Server

Sreeport includes a Model Context Protocol server for assistants and tools that can speak MCP over stdio.

## Install

```bash
npm install -g @sreeport/mcp
```

## Configure a Client

Point your MCP client at `sreeport-mcp` and set `--cwd` to the workspace containing `sreeport.config.ts`.

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

If you keep Sreeport runtime state outside the default app-support directories, also pass `--config-dir`.

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

The server exposes:

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

## Privacy

The MCP server reads the same project-local configuration as the CLI. It does not ship private mappings, environment files, logs, or machine state in the package. MCP clients can access whatever workspace you point `--cwd` at, so only configure it for workspaces you are comfortable exposing to that client.
