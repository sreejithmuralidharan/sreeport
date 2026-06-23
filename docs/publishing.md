# Publishing

The first public release targets GitHub and npm.

## Packages

- `@sreeport/core`
- `@sreeport/cli`
- `@sreeport/next`

## Preflight

```bash
pnpm lint
pnpm typecheck
pnpm test
pnpm build
pnpm pack:dry
```

## npm

You must be logged in to npm and have access to the `@sreeport` scope.

```bash
npm whoami
pnpm -r --filter './packages/*' publish --access public
```

## GitHub

```bash
gh repo create sreejithmuralidharan/sreeport --public --source=. --remote=origin --push
git tag v0.1.0
git push origin v0.1.0
gh release create v0.1.0 --title "Sreeport v0.1.0" --notes-file CHANGELOG.md
```

## macOS App

The Swift package currently builds the menu-bar app binary. A signed, notarized app bundle and Homebrew Cask are planned after the CLI/core API stabilizes.
