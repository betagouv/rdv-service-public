const path = require("path")
const { rspack } = require("@rspack/core")

module.exports = {
  devtool: "source-map",
  entry: {
    administrate: "./app/javascript/administrate",
    application: "./app/javascript/application",
    application_agent: "./app/javascript/application_agent",
    lieux_map: "./app/javascript/lieux_map",
    application_agent_config: "./app/javascript/application_agent_config",
    charts: "./app/javascript/charts",
    rdv_plan: "./app/javascript/rdv_plan",
    mail: "./app/javascript/mail",
    instance_name: "./app/javascript/instance_name",
    headway_config: "./app/javascript/headway_config",
  },
  output: {
    filename: '[name].js',
    sourceMapFilename: '[name][ext].map',
    path: path.resolve(__dirname, "app/assets/builds"),
  },
  module: {
    rules: [
      {
        test: /\.css$/i,
        use: [
          rspack.CssExtractRspackPlugin,
          'css-loader',
        ],
      },
      {
        test: /\.s[ac]ss$/i,
        use: [
          rspack.CssExtractRspackPlugin,
          'css-loader',
          'sass-loader',
        ],
      },
    ]
  },
  resolve: {
    extensions: ['.js', '.sass', '.scss', '.css'],
  },
  plugins: [
    new rspack.CssExtractRspackPlugin(),
    new rspack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      Popper: ['popper.js', 'default'],
      Rails: ['@rails/ujs']
    }),
  ]
}
