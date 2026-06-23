import { describe, expect, it } from "vitest";
import { generateCaddyfile } from "../src/index.js";

describe("cli contract", () => {
  it("re-exports Caddyfile generation for smoke testing", () => {
    expect(generateCaddyfile([{ name: "web", domain: "web.localhost", port: 3100 }])).toContain("web.localhost");
  });
});
