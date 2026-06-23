# @sreeport/mcp

Model Context Protocol server for Sreeport.

Use this package when an MCP-capable assistant or local tool needs to inspect and control Sreeport projects through the same core behavior as the CLI.

## Install

```bash
npm install -g @sreeport/mcp
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

## Privacy

The MCP server reads the workspace you point it at with `--cwd`. Only configure it for workspaces you are comfortable exposing to your MCP client. This npm package does not include private mappings, logs, environment files, or runtime state.

## Links

- Repository: https://github.com/sreejithmuralidharan/sreeport
- Documentation: https://github.com/sreejithmuralidharan/sreeport/blob/main/docs/mcp.md
- Issues: https://github.com/sreejithmuralidharan/sreeport/issues

## License

MIT
