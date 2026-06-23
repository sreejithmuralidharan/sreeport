import { describe, expect, it } from "vitest";
import { resolveOpenCommand } from "../src/browser.js";

describe("browser", () => {
  it("uses macOS bundle identifiers when available", () => {
    const original = Object.getOwnPropertyDescriptor(process, "platform");
    Object.defineProperty(process, "platform", { value: "darwin" });
    expect(resolveOpenCommand("http://app.localhost", "safari")).toEqual({
      command: "open",
      args: ["-b", "com.apple.Safari", "http://app.localhost"]
    });
    if (original) Object.defineProperty(process, "platform", original);
  });
});
