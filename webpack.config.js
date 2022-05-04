const path = require("path")
const webpack = require("webpack")
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
  mode: "production",
  devtool: "source-map",
  entry: {
    administrate: "./app/javascript/administrate",
    application: "./app/javascript/application",
    application_agent: "./app/javascript/application_agent",
    mail: "./app/javascript/mail",
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
          MiniCssExtractPlugin.loader,
          'css-loader',
        ],
      },
      {
        test: /\.s[ac]ss$/i,
        use: [
          MiniCssExtractPlugin.loader,
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
    new MiniCssExtractPlugin(),
    new webpack.ProvidePlugin({
      $: 'jquery',
      jQuery: 'jquery',
      moment: 'moment',
      Holder: 'holderjs',
      Popper: ['popper.js', 'default'],
      Rails: ['@rails/ujs']
    }),
  ]
}
