import * as esbuild from "esbuild";
import { sassPlugin } from "esbuild-sass-plugin";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { Logger } from "sass";

const select2Plugin = {
  name: "select2-init",
  setup(build) {
    // select2's UMD wrapper enters the CommonJS branch when bundled and sets
    // module.exports = factory without calling it, leaving jQuery.fn.select2
    // uninitialized and breaking i18n files that check jQuery.fn.select2.amd.
    // Appending a self-call forces initialization.
    build.onLoad(
      { filter: /select2\/dist\/js\/select2(\.full)?\.min\.js$/ },
      async (args) => {
        const source = await fs.promises.readFile(args.path, "utf-8");
        return {
          contents:
            source +
            "\nif (typeof module.exports === 'function') module.exports();",
          loader: "js",
        };
      },
    );
  },
};

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const isWatch = process.argv.includes("--watch");
const isDev = process.env.NODE_ENV === "development";

const config = {
  entryPoints: {
    administrate: "./app/javascript/administrate",
    application: "./app/javascript/application",
    application_test: "./app/javascript/application_test",
    application_agent: "./app/javascript/application_agent",
    lieux_map: "./app/javascript/lieux_map",
    application_agent_config: "./app/javascript/application_agent_config",
    charts: "./app/javascript/charts",
    rdv_plan: "./app/javascript/rdv_plan",
    mail: "./app/javascript/mail",
    instance_name: "./app/javascript/instance_name",
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
      importMapper: (p) => p.replace(/^~/, ""),
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
