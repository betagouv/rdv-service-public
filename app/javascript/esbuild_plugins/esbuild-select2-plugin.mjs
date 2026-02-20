import fs from "fs";

export const select2Plugin = {
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
