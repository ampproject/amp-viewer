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

const gulp = require('gulp');
const babel = require('gulp-babel');
const del = require('del');

const config = {
  src: 'src/**/*.js',
};

gulp.task('build', function() {
  return gulp.src(config.src)
      .pipe(babel({
          presets: ['env']
      }))
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
  return serve();
});
