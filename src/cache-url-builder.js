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


const punycode = require('punycode');

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

/** @type {RegExp} */
const IS_PUNYCODE = /^xn--/;

/** @type {RegExp} */
const SEPARATORS = /\x2E|\u3002|\uFF0E|\uFF61/g;

/** @type {RegExp} */
const NON_ASCII = /[^ -~]/;

/** @private {number} */
const MAX_DOMAIN_LABEL_LENGTH_ = 63;

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
 * @param {string} domain The publisher domain
 * @return {string} The curls encoded domain
 */
export function constructCacheUrl(domain) {
  // TODO(chenshay): Return the complete url.
  let curlsEncoding = isEligibleForHumanReadableProxyEncoding_(domain) ?
      constructHumanReadableCurlsProxyDomain_(domain) :
      constructFallbackCurlsProxyDomain_(domain);
  if (curlsEncoding.length > MAX_DOMAIN_LABEL_LENGTH_) {
    curlsEncoding = constructFallbackCurlsProxyDomain_(domain);
  }
  return curlsEncoding;
}

/**
 * Determines whether the given domain can be validly encoded into a human
 * readable curls encoded proxy domain.  A domain is eligible as long as:
 *   It does not exceed 63 characters
 *   It does not contain a mix of right-to-left and left-to-right characters
 *   It contains a dot character
 *
 * @param {string} domain The domain to validate
 * @return {boolean}
 * @private
 */
function isEligibleForHumanReadableProxyEncoding_(domain) {
  const unicode = punycode.toUnicode(domain);
  return domain.length <= MAX_DOMAIN_LABEL_LENGTH_ &&
      !(HAS_LTR_CHARS.test(unicode) &&
        HAS_RTL_CHARS.test(unicode)) &&
      domain.indexOf('.') != -1;
}

/**
 * Constructs a human readable curls encoded proxy domain using the following
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
function constructHumanReadableCurlsProxyDomain_(domain) {
  domain = punycode.toUnicode(domain);
  domain = domain.split('-').join('--');
  domain = domain.split('.').join('-');
  return punycode.toASCII(domain).toLowerCase();;
}

/**
 * Constructs a fallback curls encoded proxy domain by taking the SHA256 of
 * the domain and base32 encoding it.
 *
 * @param {string} domain The publisher domain
 * @private
 */
function constructFallbackCurlsProxyDomain_(domain) {
  // TODO(chenshay) : Implement this.
  return domain;
}
