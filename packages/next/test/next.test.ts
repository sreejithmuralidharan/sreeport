import { describe, expect, it } from "vitest";
import { nextDevCommand, withSreeportNextConfig } from "../src/index.js";

describe("@sreeport/next", () => {
  it("adds allowed dev origins", () => {
    const config = withSreeportNextConfig(
      { allowedDevOrigins: ["http://existing.localhost"] },
      { project: { domain: "web.localhost", port: 3100 } }
    );

    expect(config.allowedDevOrigins).toContain("http://existing.localhost");
    expect(config.allowedDevOrigins).toContain("http://web.localhost");
    expect(config.allowedDevOrigins).toContain("http://127.0.0.1:3100");
  });

  it("builds a deterministic dev command", () => {
    expect(nextDevCommand({ port: 3100 })).toBe("next dev -p 3100 -H 127.0.0.1");
  });
});
