import { describe, expect, it } from "vitest";
import { normalizeConfig } from "../src/config.js";
import { validateProjects } from "../src/validation.js";

describe("config", () => {
  it("normalizes project defaults", () => {
    const config = normalizeConfig({
      projects: [{ name: "web", domain: "web.localhost", port: 3100 }]
    }, "/tmp/example");

    expect(config.projects[0]).toMatchObject({
      name: "web",
      domain: "web.localhost",
      port: 3100,
      browser: "default",
      framework: "custom",
      visible: true
    });
    expect(config.projects[0]?.cwd).toBe("/tmp/example");
  });

  it("reports duplicate ports and domains", () => {
    const errors = validateProjects([
      { name: "one", domain: "app.localhost", port: 3100 },
      { name: "two", domain: "app.localhost", port: 3100 }
    ]);

    expect(errors.join("\n")).toContain("duplicate domain");
    expect(errors.join("\n")).toContain("duplicate port");
  });
});
