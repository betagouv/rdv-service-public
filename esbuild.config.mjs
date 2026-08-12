import * as esbuild from "esbuild";
import { sassPlugin } from "esbuild-sass-plugin";
import path from "path";
import { fileURLToPath } from "url";
import { Logger } from "sass";
import { select2Plugin } from "./app/javascript/esbuild_plugins/esbuild-select2-plugin.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const isWatch = process.argv.includes("--watch");
const isDev = process.env.NODE_ENV === "development";

const config = {
  entryPoints: {
    application: "./app/javascript/application",
    application_agent: "./app/javascript/application_agent",
    application_agent_config: "./app/javascript/application_agent_config",
    application_test: "./app/javascript/application_test",
    charts: "./app/javascript/charts",
    instance_name: "./app/javascript/instance_name",
    lieux_map: "./app/javascript/lieux_map",
    mail: "./app/javascript/mail",
    rdv_plan: "./app/javascript/rdv_plan",
    super_admin: "./app/javascript/super_admin",
  },
  bundle: true,
  outdir: "app/assets/builds",
  sourcemap: true,
  minify: !isDev,
  define: { global: "globalThis" },
  inject: ["./app/javascript/inject-globals.js"],
  plugins: [
    select2Plugin,
    sassPlugin({
      loadPaths: [path.resolve(__dirname, "node_modules")],
      logger: Logger.silent,
    }),
  ],
  loader: { ".svg": "file" },
  resolveExtensions: [".js", ".scss", ".sass", ".css"],
  logLevel: "info",
};

if (isWatch) {
  const ctx = await esbuild.context(config);
  await ctx.watch();
} else {
  await esbuild.build(config);
}
