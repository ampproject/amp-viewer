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
const fs = require('fs-extra');
const gulp = require('gulp');
const browserify = require('browserify');
const babelify = require('babelify');
const del = require('del');
const source = require('vinyl-source-stream');
const buffer = require('vinyl-buffer');
const rename = require('gulp-rename');

const config = {
  src: ['src/*.js'],
};

gulp.task('build', function() {
  const bundler = browserify('./src/viewer.js', {debug: true})
     .transform(babelify, {
       global: true,
       ignore: /\/node_modules\/(?!amp-viewer-messaging\/)/
     });

  return bundler.bundle()
      .pipe(source('src/viewer.js'))
      .pipe(buffer())
      .pipe(rename('viewer.js'))
      .pipe(gulp.dest('dist'));
});

gulp.task('clean', function() {
  return del(['dist']);
});

function serve() {
  var app = require('express')();
  var webserver = require('gulp-webserver');

  var host = 'localhost';
  var port = process.env.PORT || 8000;
  var server = gulp.src(process.cwd())
      .pipe(webserver({
        port,
        host,
        directoryListing: true,
        livereload: true,
        https: false,
        middleware: [app],
      }));

  return server;
}

gulp.task('default', function() {
  serve();
  return $$.watch(config.src, {ignoreInitial: false},
      $$.batch(function(events, done) {
        gulp.start('build', done);
      }));
});
