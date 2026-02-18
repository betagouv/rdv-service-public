import { compileString } from "sass";
import path from "path";
import fs from "fs";

const projectRoot = import.meta.dir;
const nodeModulesPath = path.join(projectRoot, "node_modules");

const entryPointDir = path.resolve(projectRoot, "app/javascript");

const globalsPlugin = {
  name: "globals",
  setup(build) {
    // Prepend globals import into each entry point so that window.jQuery,
    // window.$, etc. are set before any other code (including jQuery plugins
    // like select2 and bootstrap that expect them as globals).
    build.onLoad({ filter: /app\/javascript\/[^/]+\.js$/ }, (args) => {
      // Only prepend to entry points (files directly in app/javascript/)
      if (path.dirname(args.path) !== entryPointDir) return undefined;
      const source = fs.readFileSync(args.path, "utf-8");
      return {
        contents: `import './globals.js';\n${source}`,
        loader: "js",
      };
    });
  },
};

const select2Plugin = {
  name: "select2-init",
  setup(build) {
    // select2's UMD wrapper, when bundled by Bun, enters the CommonJS branch
    // and sets module.exports = factory without calling it. This leaves
    // jQuery.fn.select2 uninitialized, breaking the i18n file which checks
    // jQuery.fn.select2.amd. Appending a self-call forces initialization.
    build.onLoad({ filter: /select2\/dist\/js\/select2(\.full)?\.min\.js$/ }, (args) => {
      const source = fs.readFileSync(args.path, "utf-8");
      return {
        contents: source + "\nif (typeof module.exports === 'function') module.exports();",
        loader: "js",
      };
    });
  },
};

const sassPlugin = {
  name: "sass",
  setup(build) {
    // Resolve imports without extension to .scss files
    build.onResolve({ filter: /\.\/stylesheets/ }, (args) => {
      const dir = args.importer ? path.dirname(args.importer) : projectRoot;
      for (const ext of [".scss", ".sass", ".css"]) {
        const candidate = path.resolve(dir, args.path + ext);
        if (fs.existsSync(candidate)) {
          return { path: candidate };
        }
      }
      return undefined;
    });

    build.onLoad({ filter: /\.scss$/ }, (args) => {
      // Read the SCSS file and strip webpack's ~ prefix from imports
      const source = fs.readFileSync(args.path, "utf-8");
      const processed = source.replace(/@import\s+["']~([^"']+)["']/g, '@import "$1"');

      const result = compileString(processed, {
        url: new URL("file://" + args.path),
        loadPaths: [path.dirname(args.path), nodeModulesPath],
      });
      return {
        contents: result.css,
        loader: "css",
      };
    });
  },
};

const result = await Bun.build({
  entrypoints: [
    "./app/javascript/administrate.js",
    "./app/javascript/application.js",
    "./app/javascript/application_test.js",
    "./app/javascript/application_agent.js",
    "./app/javascript/lieux_map.js",
    "./app/javascript/application_agent_config.js",
    "./app/javascript/charts.js",
    "./app/javascript/rdv_plan.js",
    "./app/javascript/mail.js",
    "./app/javascript/instance_name.js",
  ],
  outdir: "./app/assets/builds",
  naming: "[name].[ext]",
  sourcemap: "external",
  define: {
    "global": "window",
  },
  plugins: [globalsPlugin, select2Plugin, sassPlugin],
});

if (!result.success) {
  console.error("Build failed:");
  for (const message of result.logs) {
    console.error(message);
  }
  process.exit(1);
} else {
  console.log(`Build succeeded: ${result.outputs.length} files written to app/assets/builds/`);
}
