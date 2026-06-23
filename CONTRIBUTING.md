# Contributing

Thanks for considering a contribution to Sreeport.

## Local setup

```bash
pnpm install
pnpm typecheck
pnpm test
pnpm build
```

## Guidelines

- Keep project config portable and free of machine-specific defaults.
- Do not commit personal project mappings, local logs, PID files, or generated Caddy state.
- Prefer small, focused pull requests.
- Add tests for config parsing, command behavior, and generated proxy output.
- Keep the macOS app native and lightweight.

## Release checks

```bash
pnpm lint
pnpm typecheck
pnpm test
pnpm build
pnpm pack:dry
```
