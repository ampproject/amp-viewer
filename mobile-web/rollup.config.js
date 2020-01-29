/**
 * Copyright 2020 The AMP HTML Authors. All Rights Reserved.
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

import babel from 'rollup-plugin-babel';
import resolve from '@rollup/plugin-node-resolve';
import serve from 'rollup-plugin-serve';

const plugins = [
  resolve(),
  babel({
    exclude: 'node_modules/**'
  }),
  serve({
    open: true,
    openPage: '/platform.html',
    contentBase: ['dist', 'example'],
    host: 'localhost',
    port: 8000,
    historyApiFallback: '/platform.html',
    headers: {
      'Access-Control-Allow-Origin': '*',
    },
  })
];

export default [{
  input: './src/viewer.js',
  output: {
    file: './dist/viewer.js',
    format: 'iife',
  },
  plugins,
},
{
  input: './ampkit/ampkit-url-creator.js',
  output: {
    file: './dist/ampkit-url-creator.js',
    format: 'iife'
  },
  plugins,
}];
