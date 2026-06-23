import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const root = path.resolve(new URL("..", import.meta.url).pathname);
const macDir = path.join(root, "apps/mac");
const executable = path.join(macDir, ".build/arm64-apple-macosx/debug/SreeportMac");
const appDir = path.join(root, "dist/Sreeport.app");
const contents = path.join(appDir, "Contents");
const macos = path.join(contents, "MacOS");
const resources = path.join(contents, "Resources");

const build = spawnSync("swift", ["build"], {
  cwd: macDir,
  stdio: "inherit"
});
if (build.status !== 0) process.exit(build.status ?? 1);

fs.rmSync(appDir, { recursive: true, force: true });
fs.mkdirSync(macos, { recursive: true });
fs.mkdirSync(resources, { recursive: true });

fs.copyFileSync(executable, path.join(macos, "SreeportMac"));
fs.chmodSync(path.join(macos, "SreeportMac"), 0o755);
fs.copyFileSync(path.join(root, "assets/sreeport-mark.svg"), path.join(resources, "sreeport-mark.svg"));

fs.writeFileSync(
  path.join(contents, "Info.plist"),
  `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>SreeportMac</string>
  <key>CFBundleIdentifier</key>
  <string>uk.co.sreejith.sreeport</string>
  <key>CFBundleName</key>
  <string>Sreeport</string>
  <key>CFBundleDisplayName</key>
  <string>Sreeport</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.3</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
`
);

console.log(appDir);
