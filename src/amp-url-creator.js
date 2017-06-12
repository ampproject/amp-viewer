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

// TODO(chenshay) : Write tests once testing capabilites are hooked up for this project.

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
 * @param {string} opt_viewerJsVersion
 * @return {!Promise}
 * @private
 */
export function constructViewerCacheUrl(url, initParams,
  opt_cacheUrlAuthority, opt_viewerJsVersion) {
  const parsedUrl = parseUrl(url);
  const protocolStr = parsedUrl.protocol == 'https:' ? 's/' : '';
  const viewerJsVersion = opt_viewerJsVersion ? opt_viewerJsVersion :
    DEFAULT_VIEWER_JS_VERSION_;

  return new Promise(resolve => {
    constructCacheDomainUrl_(url, opt_cacheUrlAuthority).then(cacheDomain => {
      resolve(
        cacheDomain + 
          '/v/' +
          protocolStr +
          parsedUrl.host + 
          '/?amp_js_v=' + viewerJsVersion +
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
 * @return {!Promise}
 * @private
 */
function constructCacheDomainUrl_(url, opt_cacheUrlAuthority) {
  return new Promise(resolve => {
    const cacheUrlAuthority = 
      opt_cacheUrlAuthority ? opt_cacheUrlAuthority : DEFAULT_CACHE_AUTHORITY_;
      constructCacheDomain_(url).then(cacheDomain => {
        resolve(cacheDomain + '.' + cacheUrlAuthority);
      });
  });
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
 * @return {!Promise}
 * @private
 */
function constructCacheDomain_(url) {
  return new Promise(resolve => {
    if (isEligibleForHumanReadableCacheEncoding_(url)) {
      const curlsEncoding = constructHumanReadableCurlsCacheDomain_(url);
      if (curlsEncoding.length > MAX_DOMAIN_LABEL_LENGTH_) {
        constructFallbackCurlsCacheDomain_(url).then(resolve);
      } else {
        resolve(curlsEncoding);
      }
    } else {
      constructFallbackCurlsCacheDomain_(url).then(resolve);
    }
  });
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
 * @return {!Promise}
 * @private
 */
function constructFallbackCurlsCacheDomain_(domain) {
  return new Promise(resolve => {
    sha256_(domain).then(digest => {
      resolve(base32Encode_(digest));
    });
  });
}

/**
 * @param {string} str The string to convert to sha256
 * @return {!Promise}
 * @private
 */
function sha256_(str) {
  // Transform the string into an arraybuffer.
  const buffer = new TextEncoder('utf-8').encode(str);
  return crypto.subtle.digest('SHA-256', buffer).then(hash => {
    return hex_(hash);
  });
}

/**
 * @param {string} buffer
 * @return {!Promise}
 * @private
 */
function hex_(buffer) {
  let hexCodes = [];
  const view = new DataView(buffer);
  for (let i = 0; i < view.byteLength; i += 4) {
    // Using getUint32 reduces the number of iterations needed (we process 4 bytes each time)
    const value = view.getUint32(i);
    // toString(16) will give the hex representation of the number without padding
    const stringValue = value.toString(16);
    // Use concatenation and slice for padding
    const padding = '00000000';
    const paddedValue = (padding + stringValue).slice(-padding.length);
    hexCodes.push(paddedValue);
  }

  // Join all the hex strings into one
  return hexCodes.join('');
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

 /**
   * Encodes a hex string in base 32 according to specs in RFC 4648 section 6.
   * Unfortunately, our only conversion tool is recodeString_ which
   * converts a string from base16 to base32 numerically, trimming off leading
   * 0's in the process. We use baseN to perform a base32 encoding as follows:
   *   Start with 256 bit sha encoded as a 64 char hex string
   *   Append 24 bits (6 hex chars) for a total of 280, exactly 7 40-bit chunks
   *   Prepend a 40-bit block of 1's (10 'f' chars) so that basen doesn't trim
   *     the beginning when converting
   *   Call basen
   *   Trim the first 8 chars (the 40 1's)
   *   Trim the last 4 chars
   *
   * @param {string} hexString The hex string
   * @return {string} The base32 encoded string
   * @private
   */
function base32Encode_(hexString) {
  const initialPadding = 'ffffffffff';
  const finalPadding = '000000';
  const paddedString = initialPadding + hexString + finalPadding;
  const base16 = '0123456789abcdef';
  // We use the base32 character encoding defined here:
  // https://tools.ietf.org/html/rfc4648
  const base32 = 'abcdefghijklmnopqrstuvwxyz234567';
  // Convert number (paddedString) from base16 to base32
  const recodedString = recodeString_(paddedString, base16, base32);

  const bitsPerHexChar = 4;
  const bitsPerBase32Char = 5;
  const numInitialPaddingChars =
      initialPadding.length * bitsPerHexChar / bitsPerBase32Char;
  const numHexStringChars =
      Math.ceil(hexString.length * bitsPerHexChar / bitsPerBase32Char);
  return recodedString.substr(numInitialPaddingChars, numHexStringChars);
}

/**
 * Converts a number from one numeric base to another.
 *
 * The bases are represented as strings, which list allowed digits.  Each digit
 * should be unique.
 *
 * The number is in human-readable format, most significant digit first, and is
 * a non-negative integer.  Base designators such as $, 0x, d, b or h (at end)
 * will be interpreted as digits, so avoid them.  Leading zeros will be trimmed.
 *
 * Note: for huge bases the result may be inaccurate because of overflowing
 * 64-bit doubles used by JavaScript for integer calculus.  This may happen
 * if the product of the number of digits in the input and output bases comes
 * close to 10^16, which is VERY unlikely (100M digits in each base), but
 * may be possible in the future unicode world.  (Unicode 3.2 has less than 100K
 * characters.  However, it reserves some more, close to 1M.)
 *
 * @param {string} number The number to convert.
 * @param {string} inputBase The numeric base the number is in (all digits).
 * @param {string} outputBase Requested numeric base.
 * @return {string} The converted number.
 * @private
 */
function recodeString_(number, inputBase, outputBase) {
  if (outputBase == '') {
    throw Error('Empty output base');
  }

  // Check if number is 0 (special case when we don't want to return '').
  let isZero = true;
  for (let i = 0, n = number.length; i < n; i++) {
    if (number.charAt(i) != inputBase.charAt(0)) {
      isZero = false;
      break;
    }
  }
  if (isZero) {
    return outputBase.charAt(0);
  }

  const numberDigits = stringToArray_(number, inputBase);

  const inputBaseSize = inputBase.length;
  const outputBaseSize = outputBase.length;

  // result = 0.
  let result = [];

  // For all digits of number, starting with the most significant
  for (let i = numberDigits.length - 1; i >= 0; i--) {
    // result *= number.base.
    let carry = 0;
    for (let j = 0, n = result.length; j < n; j++) {
      let digit = result[j];
      // This may overflow for huge bases.  See function comment.
      digit = digit * inputBaseSize + carry;
      if (digit >= outputBaseSize) {
        const remainder = digit % outputBaseSize;
        carry = (digit - remainder) / outputBaseSize;
        digit = remainder;
      } else {
        carry = 0;
      }
      result[j] = digit;
    }
    while (carry) {
      const remainder = carry % outputBaseSize;
      result.push(remainder);
      carry = (carry - remainder) / outputBaseSize;
    }

    // result += number[i].
    carry = numberDigits[i];
    let j = 0;
    while (carry) {
      if (j >= result.length) {
        // Extend result with a leading zero which will be overwritten below.
        result.push(0);
      }
      let digit = result[j];
      digit += carry;
      if (digit >= outputBaseSize) {
        const remainder = digit % outputBaseSize;
        carry = (digit - remainder) / outputBaseSize;
        digit = remainder;
      } else {
        carry = 0;
      }
      result[j] = digit;
      j++;
    }
  }

  return arrayToString_(result, outputBase);
};

/**
 * Converts a string representation of a number to an array of digit values.
 *
 * More precisely, the digit values are indices into the number base, which
 * is represented as a string, which can either be user defined or one of the
 * BASE_xxx constants.
 *
 * Throws an Error if the number contains a digit not found in the base.
 *
 * @param {string} number The string to convert, most significant digit first.
 * @param {string} base Digits in the base.
 * @return {!Array<number>} Array of digit values, least significant digit
 *     first.
 * @private
 */
function stringToArray_(number, base) {
  let index = {};
  for (let i = 0, n = base.length; i < n; i++) {
    index[base.charAt(i)] = i;
  }
  let result = [];
  for (let i = number.length - 1; i >= 0; i--) {
    const character = number.charAt(i);
    const digit = index[character];
    if (typeof digit == 'undefined') {
      throw Error(
          'Number ' + number + ' contains a character not found in base ' +
          base + ', which is ' + character);
    }
    result.push(digit);
  }
  return result;
};

/**
 * Converts an array representation of a number to a string.
 *
 * More precisely, the elements of the input array are indices into the base,
 * which is represented as a string.
 *
 * Throws an Error if the number contains a digit which is outside the range
 * 0 ... base.length - 1.
 *
 * @param {Array<number>} number Array of digit values, least significant
 *     first.
 * @param {string} base Digits in the base.
 * @return {string} Number as a string, most significant digit first.
 * @private
 */
function arrayToString_(number, base) {
  const n = number.length;
  const chars = [];
  const baseSize = base.length;
  for (let i = n - 1; i >= 0; i--) {
    const digit = number[i];
    if (digit >= baseSize || digit < 0) {
      throw Error('Number ' + number + ' contains an invalid digit: ' + digit);
    }
    chars.push(base.charAt(digit));
  }
  return chars.join('');
};
