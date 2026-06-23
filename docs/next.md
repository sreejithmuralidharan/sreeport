# Next.js Integration

Sreeport treats Next.js as a first-class framework, but the main product is not a Next.js app. The core and CLI are framework-agnostic.

## Initialize

```bash
sreeport next init --name web --domain web.localhost --port 3100
```

## Next Config Helper

```ts
import { withSreeportNextConfig } from "@sreeport/next";

export default withSreeportNextConfig(
  {},
  {
    project: {
      domain: "web.localhost",
      port: 3100
    }
  }
);
```

The helper adds local dev origins for the configured domain and loopback port.

## Start Command

Sreeport starts Next with explicit host and port:

```bash
next dev -p 3100 -H 127.0.0.1
```

If your project needs setup work before Next starts, define `command` in `sreeport.config.ts`.

```ts
command: "prisma generate && next dev -p 3100 -H 127.0.0.1"
```
