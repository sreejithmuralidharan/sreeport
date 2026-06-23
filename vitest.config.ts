import { defineConfig } from "vitest/config";
import { fileURLToPath } from "node:url";
import path from "node:path";

const root = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  resolve: {
    alias: {
      "@sreeport/core": path.join(root, "packages/core/src/index.ts"),
      "@sreeport/next": path.join(root, "packages/next/src/index.ts")
    }
  }
});
