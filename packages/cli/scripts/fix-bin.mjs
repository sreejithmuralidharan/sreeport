import fs from "node:fs";
import path from "node:path";

const binPath = path.resolve("dist/index.js");
const content = fs.readFileSync(binPath, "utf8");
if (!content.startsWith("#!/usr/bin/env node")) {
  fs.writeFileSync(binPath, `#!/usr/bin/env node\n${content}`);
}
fs.chmodSync(binPath, 0o755);
