import { describe, expect, it } from "vitest";
import { generateCaddyfile } from "../src/caddy.js";

describe("caddy", () => {
  it("generates routes and a fallback", () => {
    const caddyfile = generateCaddyfile([
      { name: "web", domain: "web.localhost", port: 3100 }
    ]);

    expect(caddyfile).toContain("http://web.localhost");
    expect(caddyfile).toContain("reverse_proxy 127.0.0.1:3100");
    expect(caddyfile).toContain("respond \"No Sreeport project configured for this host.\" 404");
  });
});
