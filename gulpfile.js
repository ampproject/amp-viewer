/**
 * Copyright 2017 The AMP HTML Authors. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS-IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

const $$ = require('gulp-load-plugins')();
const gulp = require('gulp');
const del = require('del');
const source = require('vinyl-source-stream');
const buffer = require('vinyl-buffer');
const rename = require('gulp-rename');
const webpack = require('webpack');
const config = require('./webpack.config');
const WebpackDevServer = require("webpack-dev-server");
const minimist = require('minimist');
var argv = minimist(process.argv.slice(2), {boolean: ['strictBabelTransform']});

if (argv.watch) {
  config.watch = true;
}


const sources = ['src/**/*.js'];

gulp.task('default', ['build']);

gulp.task('build', function(cb) {
  webpack(config, function(err, stats) {
    if(err) throw new $$.util.PluginError('webpack', err);
    $$.util.log('[webpack]', stats.toString(config));
    cb();
  });
});

gulp.task('clean', function(cb) {
  return del(['dist'], cb);
});

gulp.task('serve', function() {
 // Start a webpack-dev-server
  var compiler = webpack(config);

  new WebpackDevServer(compiler, {})
      .listen(8000, 'localhost', function(err) {
        if (err) {
          throw new $$.util.PluginError('webpack-dev-server', err);
        }
        $$.util.log('[webpack-dev-server]');
      });
});

gulp.task('watch', ['serve'], function(done) {
  return $$.watch(sources, {ignoreInitial: false}, function() {
    gulp.start('default', done);
  });
});
