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
const express = require('express');
const del = require('del');
const webpack = require('webpack');
const config = require('./webpack.config');
const WebpackDevServer = require('webpack-dev-server');
const minimist = require('minimist');
const runSequence = require('run-sequence');
var argv = minimist(process.argv.slice(2));


const sources = ['src/**/*.js'];

gulp.task('default', ['build']);
gulp.task('watch', function(cb) {
  argv.watch = true;
  runSequence('serve', 'build', cb)
});

gulp.task('build', function(cb) {
  var webpackConfig = config;
  if (argv.watch) {
    webpackConfig = Object.assign({watch: !!argv.watch}, config);
  }

  webpack(webpackConfig, function(err, stats) {
    if(err) {
      throw new $$.util.PluginError('webpack:error', err);
    }
    $$.util.log('[webpack]', stats.toString(config));
    if (!argv.watch) {
      cb();
    }
  });
});

gulp.task('clean', function(cb) {
  return del(['dist'], cb);
});

gulp.task('serve', function() {
  var app = express();
  // Start a webpack-dev-server
  var compiler = webpack(config);
  new WebpackDevServer(compiler, {})
      .listen(8000, 'localhost', function(err) {
        if (err) {
          throw new gutil.PluginError('webpack-dev-server', err);
        }
        // Server listening
        $$.util.log('[webpack-dev-server]');
        // keep the server alive or continue?
        // callback();
    });
});
