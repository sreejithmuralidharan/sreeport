# @sreeport/core

Core engine for Sreeport local development orchestration.

Use this package when you want to load Sreeport config, validate project mappings, inspect process state, generate Caddy config, or build tooling on top of Sreeport.

## Install

```bash
npm install @sreeport/core
```

## Example

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

## Configuration

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
      framework: "custom"
    }
  ]
});
```

## Privacy

This package does not include machine-specific project mappings, logs, environment files, or runtime state. It only ships the reusable core implementation.

## Links

- Repository: https://github.com/sreejithmuralidharan/sreeport
- Documentation: https://github.com/sreejithmuralidharan/sreeport#readme
- Issues: https://github.com/sreejithmuralidharan/sreeport/issues

## License

MIT
