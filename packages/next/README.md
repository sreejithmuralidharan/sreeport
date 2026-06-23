# @sreeport/next

Next.js integration helpers for Sreeport.

Use this package to keep Next.js development origins aligned with the stable ports and `.localhost` domains managed by Sreeport.

## Install

```bash
npm install -D @sreeport/next
```

## Next Config

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

## Sreeport Config

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

## Privacy

This package only ships the Next.js helper. It does not include private project mappings, logs, environment files, or runtime state.

## Links

- Repository: https://github.com/sreejithmuralidharan/sreeport
- Documentation: https://github.com/sreejithmuralidharan/sreeport/blob/main/docs/next.md
- Issues: https://github.com/sreejithmuralidharan/sreeport/issues

## License

MIT
