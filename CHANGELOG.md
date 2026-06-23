# Changelog

## Unreleased

- Redesigned the macOS menu-bar dashboard with metric tiles, clearer project rows, and icon-based actions.
- Fixed the project list area so configured projects remain visible instead of collapsing beneath the toolbar.
- Added an in-menu output panel for command results and project logs.
- Improved the packaged macOS app workflow so local workspace state is loaded from Sreeport application support.
- Replaced the passive proxy and gear controls with a stateful Restart Proxy control and an actionable workspace tools panel.
- Added CLI proxy status output for menu-bar UI status and diagnostics.
- Reworked the macOS menu controls into a visible proxy status card, always-available quick tools, project filters, and explicit command completion output.
- Expanded the settings window with actionable workspace, proxy, diagnostics, and status controls.
- Made macOS menu actions non-blocking with per-button loading indicators, an in-menu progress bar, and immediate command feedback while CLI tasks run.
- Moved macOS command feedback above the project list, stabilized the output panel height to prevent layout jumps, and made logs a labeled action.
- Added `@sreeport/mcp`, a stdio Model Context Protocol server for status, start/stop/restart, logs, doctor checks, browser open, and proxy management.
- Documented MCP installation, client configuration, tool coverage, and npm scope publishing requirements.

## 0.1.0

- Initial public project structure.
- Cross-platform core and CLI.
- Next.js integration package.
- Native macOS menu-bar app scaffold.
- Sreeport harbor-route SVG icon.
