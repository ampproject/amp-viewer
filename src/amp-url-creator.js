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


import {parseUrl} from '../utils/url';

const punycode = require('punycode');

/** @private {string} The default AMP cache prefix to be used. */
const DEFAULT_CACHE_AUTHORITY_ = 'cdn.ampproject.org';

/**
 * The default JavaScript version to be used for AMP viewer URLs.
 * @private {string}
 */
const DEFAULT_VIEWER_JS_VERSION_ = '0.1';

/** @type {string} */
const LTR_CHARS =
  'A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02B8\u0300-\u0590\u0800-\u1FFF' +
  '\u200E\u2C00-\uFB1C\uFE00-\uFE6F\uFEFD-\uFFFF';

/** @type {string} */
const RTL_CHARS =
  '\u0591-\u06EF\u06FA-\u07FF\u200F\uFB1D-\uFDFF\uFE70-\uFEFC';

/** @type {RegExp} */
const HAS_LTR_CHARS = new RegExp('[' + LTR_CHARS + ']');

/** @type {RegExp} */
const HAS_RTL_CHARS = new RegExp('[' + RTL_CHARS + ']');

/** @private {number} */
const MAX_DOMAIN_LABEL_LENGTH_ = 63;


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
 * @param {string} opt_viewer_js_version
 * @return {string} the Cache Url.
 * @private
 */
export function constructViewerCacheUrl(url, initParams,
  opt_cacheUrlAuthority, opt_viewer_js_version) {
  const parsedUrl = parseUrl(url);
  const cacheDomain = constructCacheDomainUrl_(url, opt_cacheUrlAuthority);
  const protocolStr = parsedUrl.protocol == 'https:' ? 's/' : '';
  const viewerJsVersion = opt_viewer_js_version ? opt_viewer_js_version :
    DEFAULT_VIEWER_JS_VERSION_;

  return cacheDomain + 
          '/v/' +
          protocolStr +
          parsedUrl.host + 
          '/?amp_js_v=' + viewerJsVersion +
          '#' +
          paramsToString_(initParams);
}

/**
 * Constructs a cache domain url. For example:
 * 
 * Input url 'http://ampproject.org'
 * will return  'https://www-ampproject-org.cdn.ampproject.org'
 * 
 * @param {string} url The complete publisher url.
 * @param {string} opt_cacheUrlAuthority
 * @return {string}
 * @private
 */
function constructCacheDomainUrl_(url, opt_cacheUrlAuthority) {
  const cacheUrlAuthority = 
    opt_cacheUrlAuthority ? opt_cacheUrlAuthority : DEFAULT_CACHE_AUTHORITY_;
  return constructCacheDomain_(url) + '.' + cacheUrlAuthority;
}

/**
 * Constructs a curls domain following these instructions:
 * 1. Convert pub.com from IDN (punycode) to utf-8, if applicable.
 * 2. Replace every “-” with “--”.
 * 3. Replace each “.” with “-”.
 * 4. Convert back to IDN.
 * 
 * Examples:
 *   'something.com'    =>  'something-com'
 *   'SOMETHING.COM'    =>  'something-com'
 *   'hello-world.com'  =>  'hello--world-com'
 *   'hello--world.com' =>  'hello----world-com'
 * 
 * Fallback applies to the following cases:
 * - RFCs don’t permit a domain label to exceed 63 characters.
 * - RFCs don’t permit any domain label to contain a mix of right-to-left and
 *   left-to-right characters.
 * - If the origin domain contains no “.” character.
 * 
 * Fallback Algorithm:
 * 1. Take the SHA256 of the punycode view of the domain.
 * 2. Base32 encode the resulting hash. Set the domain prefix to the resulting
 *    string.
 *
 * @param {string} url The complete publisher url.
 * @return {string} The curls encoded domain
 * @private
 */
function constructCacheDomain_(url) {
  let curlsEncoding = isEligibleForHumanReadableCacheEncoding_(url) ?
      constructHumanReadableCurlsCacheDomain_(url) :
      constructFallbackCurlsCacheDomain_(url);
  if (curlsEncoding.length > MAX_DOMAIN_LABEL_LENGTH_) {
    curlsEncoding = constructFallbackCurlsCacheDomain_(url);
  }
  return curlsEncoding;
}

/**
 * Determines whether the given domain can be validly encoded into a human
 * readable curls encoded cache domain.  A domain is eligible as long as:
 *   It does not exceed 63 characters
 *   It does not contain a mix of right-to-left and left-to-right characters
 *   It contains a dot character
 *
 * @param {string} domain The domain to validate
 * @return {boolean}
 * @private
 */
function isEligibleForHumanReadableCacheEncoding_(domain) {
  const unicode = punycode.toUnicode(domain);
  return domain.length <= MAX_DOMAIN_LABEL_LENGTH_ &&
      !(HAS_LTR_CHARS.test(unicode) &&
        HAS_RTL_CHARS.test(unicode)) &&
      domain.indexOf('.') != -1;
}

/**
 * Constructs a human readable curls encoded cache domain using the following
 * algorithm:
 *   Convert domain from punycode to utf-8 (if applicable)
 *   Replace every '-' with '--'
 *   Replace every '.' with '-'
 *   Convert back to punycode (if applicable)
 *
 * @param {string} domain The publisher domain
 * @return {string} The curls encoded domain
 * @private
 */
function constructHumanReadableCurlsCacheDomain_(domain) {
  domain = punycode.toUnicode(domain);
  domain = domain.split('-').join('--');
  domain = domain.split('.').join('-');
  return punycode.toASCII(domain).toLowerCase();
}

/**
 * Constructs a fallback curls encoded cache domain by taking the SHA256 of
 * the domain and base32 encoding it.
 *
 * @param {string} domain The publisher domain
 * @private
 */
function constructFallbackCurlsCacheDomain_(domain) {
  // TODO(chenshay) : Implement this.
  return domain;
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
