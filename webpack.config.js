const path = require('path');

module.exports = {
  entry: {
    'amp-viewer': './src/amp-viewer.js',
  },
  output: {
    filename: '[name].js',
    path: __dirname + '/dist'
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
  },
}
