# Publishing

The first public release targets GitHub and npm.

## Packages

- `@sreeport/core`
- `@sreeport/cli`
- `@sreeport/next`
- `@sreeport/mcp`

Each package should include package-specific npm metadata and a package-local `README.md` so npm renders useful install and usage guidance.

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
pnpm -r --filter './packages/*' publish --access public --otp 123456
```

Replace `123456` with a current npm two-factor code. If the `@sreeport` scope does not exist yet, create the `sreeport` npm organization first and make sure your user is an owner.

## GitHub

```bash
gh repo create sreejithmuralidharan/sreeport --public --source=. --remote=origin --push
git tag v0.1.2
git push origin v0.1.2
gh release create v0.1.2 --title "Sreeport v0.1.2" --notes-file CHANGELOG.md
```

## macOS App

The Swift package currently builds the menu-bar app binary. A signed, notarized app bundle and Homebrew Cask are planned after the CLI/core API stabilizes.
