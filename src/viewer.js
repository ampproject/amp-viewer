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

import {constructViewerProxyUrl} from './amp-url-creator';
import {ViewerMessaging} from './viewer-messaging';
import {log} from '../utils/log';
import {parseUrl} from '../utils/url';

/**
 * This file is a Viewer for AMP Documents.
 */
class Viewer {

  /**
   * @param {!Window} win
   * @param {!Element} hostElement the element to attatch the iframe to.
   * @param {string} ampDocUrl the AMP Document url.
   */
  constructor(hostElement, ampDocUrl) {
    /** @private {ViewerMessaging} */
    this.viewerMessaging_ = null;

    /** @private {!Element} */
    this.hostElement_ = hostElement;

    /** @private {string} */
    this.ampDocUrl_ = ampDocUrl;

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

    const ampDocCachedUrl = this.buildIframeSrc_()

    this.viewerMessaging_ = new ViewerMessaging(
      window,
      this.iframe_,
      parseUrl(ampDocCachedUrl).origin);

    this.viewerMessaging_.start().then(()=>{
      log('this.viewerMessaging_.start() Promise resolved !!!');
    });

    this.iframe_.src = ampDocCachedUrl;
    this.hostElement_.appendChild(this.iframe_);
  }

  /**
   * @return {string}
   */
  buildIframeSrc_() {
    const parsedViewerUrl = parseUrl(window.location.href);

    // TODO (chenshay): create a place to set all the init params.
    const initParams = {
      origin: parsedViewerUrl.origin
    };

    return constructViewerProxyUrl(
      this.ampDocUrl_, parseUrl(this.ampDocUrl_).protocol, initParams);
  }
}
window.Viewer = Viewer;
