import { spawn } from "node:child_process";
import type { BrowserChoice } from "./types.js";

const macBrowserBundles: Record<string, string> = {
  arc: "company.thebrowser.Browser",
  chrome: "com.google.Chrome",
  firefox: "org.mozilla.firefox",
  safari: "com.apple.Safari"
};

export interface OpenCommand {
  command: string;
  args: string[];
}

export function resolveOpenCommand(url: string, browser: BrowserChoice = "default"): OpenCommand {
  if (process.platform === "darwin") {
    if (browser === "default") return { command: "open", args: [url] };
    if (browser.startsWith("bundle:")) return { command: "open", args: ["-b", browser.slice(7), url] };
    if (browser.startsWith("app:")) return { command: "open", args: ["-a", browser.slice(4), url] };
    return { command: "open", args: ["-b", macBrowserBundles[browser] ?? browser, url] };
  }

  if (process.platform === "win32") {
    return { command: "cmd", args: ["/c", "start", "", url] };
  }

  return { command: "xdg-open", args: [url] };
}

export async function openUrl(url: string, browser: BrowserChoice = "default"): Promise<void> {
  const { command, args } = resolveOpenCommand(url, browser);
  await new Promise<void>((resolve, reject) => {
    const child = spawn(command, args, {
      detached: true,
      stdio: "ignore"
    });
    child.once("error", reject);
    child.once("spawn", () => {
      child.unref();
      resolve();
    });
  });
}
