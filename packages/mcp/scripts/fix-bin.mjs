import fs from "node:fs";
import path from "node:path";

const binPath = path.join(process.cwd(), "dist/index.js");
const source = fs.readFileSync(binPath, "utf8");
if (!source.startsWith("#!/usr/bin/env node")) {
  fs.writeFileSync(binPath, `#!/usr/bin/env node\n${source}`);
}
fs.chmodSync(binPath, 0o755);
