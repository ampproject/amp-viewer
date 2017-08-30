const path = require('path');

module.exports = {
  watch: true,
  entry: {
    'ampkit-url-creator': './ampkit/ampkit-url-creator.js',
    'viewer': './src/viewer.js',
  },
  output: {
    filename: '[name].js',
    path: path.resolve(__dirname, 'dist')
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        include: [/amp-viewer-messaging/, /src/],
        use: [{
          loader: 'babel-loader',
          options: { presets: ['env'] },
        }],
      },
    ],
  },
  devServer: {
    contentBase: path.resolve(__dirname, './example'),  // New
    compress: true,
    port: 8000,
  },
}
