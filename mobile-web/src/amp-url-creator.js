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

import ampToolboxCacheUrl from 'amp-toolbox-cache-url';

import {parseUrl} from '../utils/url';

/** @private {string} The default AMP cache prefix to be used. */
const DEFAULT_CACHE_AUTHORITY_ = 'cdn.ampproject.org';

/**
 * The default JavaScript version to be used for AMP viewer URLs.
 * @private {string}
 */
const DEFAULT_VIEWER_JS_VERSION_ = '0.1';

/**
 * Constructs a Viewer cache url for native viers using these rules:
 * https://developers.google.com/amp/cache/overview
 * 
 * Example:
 * Input url 'http://ampproject.org' can return 
 * 'https://www-ampproject-org.cdn.ampproject.org/v/s/www.ampproject.org/?amp_js_v=0.1#origin=http%3A%2F%2Flocalhost%3A8000'
 * 
 * @param {string} url The complete publisher url.
 * @param {object} initParams Params containing origin, etc.
 * @param {string} opt_cacheUrlAuthority
 * @param {string} opt_viewerJsVersion
 * @return {!Promise<string>}
 * @private
 */
export function constructNativeViewerCacheUrl(url, initParams,
  opt_cacheUrlAuthority, opt_viewerJsVersion) {
	  return constructViewerCacheUrlOptions(url, true, initParams, opt_cacheUrlAuthority, opt_viewerJsVersion);
}

/**
 * Constructs a Viewer cache url using these rules:
 * https://developers.google.com/amp/cache/overview
 * 
 * Example:
 * Input url 'http://ampproject.org' can return 
 * 'https://www-ampproject-org.cdn.ampproject.org/v/s/www.ampproject.org/?amp_js_v=0.1#origin=http%3A%2F%2Flocalhost%3A8000'
 * 
 * @param {string} url The complete publisher url.
 * @param {object} initParams Params containing origin, etc.
 * @param {string} opt_cacheUrlAuthority
 * @param {string} opt_viewerJsVersion
 * @return {!Promise<string>}
 * @private
 */
export function constructViewerCacheUrl(url, initParams,
  opt_cacheUrlAuthority, opt_viewerJsVersion) {
	  return constructViewerCacheUrlOptions(url, false, initParams, opt_cacheUrlAuthority, opt_viewerJsVersion);
 }

/**
 * Constructs a Viewer cache url using these rules:
 * https://developers.google.com/amp/cache/overview
 * 
 * Example:
 * Input url 'http://ampproject.org' can return 
 * 'https://www-ampproject-org.cdn.ampproject.org/v/s/www.ampproject.org/?amp_js_v=0.1#origin=http%3A%2F%2Flocalhost%3A8000'
 * 
 * @param {string} url The complete publisher url.
 * @param {object} initParams Params containing origin, etc.
 * @param {boolean} isNative Whether or not the url generated follows rules for native viewers (like AMPKit)
 * @param {string} opt_cacheUrlAuthority
 * @param {string} opt_viewerJsVersion
 * @return {!Promise<string>}
 * @private
 */
function constructViewerCacheUrlOptions(url, isNative, initParams,
    opt_cacheUrlAuthority, opt_viewerJsVersion) {
  const parsedUrl = parseUrl(url);
  const protocolStr = parsedUrl.protocol == 'https:' ? 's/' : '';
  const viewerJsVersion = opt_viewerJsVersion ? opt_viewerJsVersion :
    DEFAULT_VIEWER_JS_VERSION_;
  const search = parsedUrl.search ? parsedUrl.search + '&' : '?';
  const pathType = isNative ? '/c/' : '/v/';
  const ampJSVersion = isNative ? '' : 'amp_js_v=' + viewerJsVersion;

  const urlProtocolAndHost = parsedUrl.protocol + '//' + parsedUrl.host;

  return new Promise(resolve => {
    constructCacheDomainUrl_(urlProtocolAndHost, opt_cacheUrlAuthority).then(cacheDomain => {
      resolve(
        'https://' +
        cacheDomain + 
        pathType +
        protocolStr +
        parsedUrl.host + 
        parsedUrl.pathname +
        search +
        ampJSVersion +
        '#' +
        paramsToString_(initParams)
      );
    });
  });
}

/**
 * Constructs a cache domain url. For example:
 * 
 * Input url 'http://ampproject.org'
 * will return  'https://www-ampproject-org.cdn.ampproject.org'
 * 
 * @param {string} url The complete publisher url.
 * @param {string} opt_cacheUrlAuthority
 * @return {!Promise<string>}
 * @private
 */
function constructCacheDomainUrl_(url, opt_cacheUrlAuthority) {
  return new Promise(resolve => {
    const cacheUrlAuthority = 
      opt_cacheUrlAuthority ? opt_cacheUrlAuthority : DEFAULT_CACHE_AUTHORITY_;
      ampToolboxCacheUrl.createCurlsSubdomain(url).then(curlsSubdomain => {
        resolve(curlsSubdomain + '.' + cacheUrlAuthority);
      });
  });
}

/**
 * Takes an object such as:
 * {
 *   origin: "http://localhost:8000",
 *   prerenderSize: 1
 * } 
 * and converts it to: "origin=http%3A%2F%2Flocalhost%3A8000&prerenderSize=1"
 * 
 * @param {object} params
 * @return {string}
 * @private
 */
function paramsToString_(params) {
  let str = '';
  for (let key in params) {
    let value = params[key];
    if (value === null || value === undefined) {
      continue;
    }
    if (str.length > 0) {
      str += '&';
    }
    str += encodeURIComponent(key) + '=' + encodeURIComponent(value);
  }
  return str;
}


