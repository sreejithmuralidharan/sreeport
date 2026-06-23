import { z } from "zod";

export const browserChoiceSchema = z.union([
  z.literal("default"),
  z.literal("safari"),
  z.literal("chrome"),
  z.literal("arc"),
  z.literal("firefox"),
  z.string().regex(/^bundle:.+/),
  z.string().regex(/^app:.+/)
]);

export const projectConfigSchema = z.object({
  name: z.string().min(1).regex(/^[a-zA-Z0-9][a-zA-Z0-9._-]*$/),
  domain: z.string().min(1),
  port: z.number().int().min(1).max(65535),
  command: z.string().min(1).optional(),
  cwd: z.string().min(1).optional(),
  browser: browserChoiceSchema.default("default"),
  framework: z.enum(["next", "vite", "custom"]).default("custom"),
  env: z.record(z.string(), z.string()).default({}),
  visible: z.boolean().default(true)
});

export const sreeportConfigSchema = z.object({
  projects: z.array(projectConfigSchema).default([])
});
