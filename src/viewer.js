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

import {ViewerMessaging} from './viewer-messaging';
import {log} from '../utils/log';

/**
 * This file is a Viewer for AMP Documents.
 */
class Viewer {

  /**
   * @param {!Window} win
   * @param {!Element} hostElement the element to attatch the iframe to.
   * @param {string} ampDocUrl the AMP Document url.
   * @param {string} ampDocCachedUrl the cached AMP Document url.
   */
  constructor(hostElement, ampDocUrl, ampDocCachedUrl) {
    /** @private {ViewerMessaging} */
    this.viewerMessaging_ = null;

    /** @private {!Element} */
    this.hostElement_ = hostElement;

    /** @private {string} */
    this.ampDocUrl_ = ampDocUrl;

    /** @private {string} */
    this.ampDocCachedUrl_ = ampDocCachedUrl;

    /** @private {?Element} */
    this.iframe_ = null;
  }

  /**
   * Attaches the AMP Doc Iframe to the Host Element.
   */
  attach() {
    this.iframe_ = document.createElement('iframe');
    // TODO (chenshay): iframe_.setAttribute('scrolling', 'no')
    // to enable the scrolling workarounds for iOS.

    this.viewerMessaging_ = new ViewerMessaging(
      window,
      this.iframe_,
      this.parseUrl(this.ampDocCachedUrl_).origin);

    this.viewerMessaging_.start().then(()=>{
      log('this.viewerMessaging_.start() Promise resolved !!!');
    });

    this.iframe_.src = this.buildIframeSrc_();
    this.hostElement_.appendChild(this.iframe_);
  }

  /**
   * @return {string}
   */
  buildIframeSrc_() {
    const parsedViewerUrl = this.parseUrl(window.location.href);

    // TODO (chenshay): support more init params like visibilityState, etc.
    const initParams = {
      origin: parsedViewerUrl.origin,
    };

    const protocolStr = parsedViewerUrl.protocol == 'https:' ? 's/' : '';

    return this.ampDocCachedUrl_ + 
            '/v/' +
            protocolStr + 
            this.ampDocUrl_ + 
            '/?amp_js_v=0.1#' + // TODO (chenshay): make version configurable.
            this.paramsToStr(initParams);
  }

  /**
   * @param {*} params
   * @return {string}
   */
  paramsToStr(params) {
    var s = '';
    for (var k in params) {
      var v = params[k];
      if (v === null || v === undefined) {
        continue;
      }
      if (s.length > 0) {
        s += '&';
      }
      s += encodeURIComponent(k) + '=' + encodeURIComponent(v);
    }
    return s;
  }

  /**
   * @param {string} urlString
   * @return {*}
   */
  parseUrl(urlString) {
    var a = document.createElement('a');
    a.href = urlString;
    return {
      href: a.href,
      protocol: a.protocol,
      host: a.host,
      hostname: a.hostname,
      port: a.port == '0' ? '' : a.port,
      pathname: a.pathname,
      search: a.search,
      hash: a.hash,
      origin: a.protocol + '//' + a.host
    };
  }
}
window.Viewer = Viewer;
