import { describe, expect, it } from "vitest";
import { isPidAlive, statusForProject } from "../src/process-manager.js";
import { getRuntimePaths } from "../src/paths.js";

describe("process state", () => {
  it("detects missing pids as not alive", () => {
    expect(isPidAlive(undefined)).toBe(false);
  });

  it("returns project status shape", () => {
    const runtime = getRuntimePaths("/tmp/sreeport-test");
    const status = statusForProject({ name: "web", domain: "web.localhost", port: 65534 }, runtime);
    expect(status).toMatchObject({
      name: "web",
      domain: "web.localhost",
      running: false,
      url: "http://web.localhost"
    });
  });
});
