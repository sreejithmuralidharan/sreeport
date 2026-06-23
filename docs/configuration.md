# Configuration

Sreeport uses project-local configuration so teams can keep mappings close to the app they describe.

## `sreeport.config.ts`

```ts
import { defineSreeportConfig } from "@sreeport/core";

export default defineSreeportConfig({
  projects: [
    {
      name: "api",
      domain: "api.localhost",
      port: 3101,
      framework: "custom",
      command: "npm run dev",
      browser: "default"
    }
  ]
});
```

## Fields

| Field | Required | Description |
| --- | --- | --- |
| `name` | Yes | Stable project identifier used by CLI commands. |
| `domain` | Yes | Local domain, usually ending in `.localhost`. |
| `port` | Yes | Local port Sreeport expects the app to listen on. |
| `command` | No | Start command. If omitted, Sreeport chooses a framework default. |
| `cwd` | No | Working directory. Defaults to the config file directory. |
| `browser` | No | Browser preference for `sreeport open`. |
| `framework` | No | `next`, `vite`, or `custom`. |
| `env` | No | Extra environment variables for the start command. |
| `visible` | No | Hide a project from UI while keeping it configured. |

## Validation

Sreeport blocks duplicate names, ports, and domains before writing proxy config.
