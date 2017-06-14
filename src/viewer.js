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

import {constructViewerCacheUrl} from './amp-url-creator';
import {ViewerMessaging} from './viewer-messaging';
import {History} from './history';
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
   * @param {!Function} hideViewer method that hides the viewer.
   */
  constructor(hostElement, ampDocUrl, hideViewer) {
    /** @private {ViewerMessaging} */
    this.viewerMessaging_ = null;

    /** @private {!Element} */
    this.hostElement_ = hostElement;

    /** @private {string} */
    this.ampDocUrl_ = ampDocUrl;

    /** @private {?Element} */
    this.iframe_ = null;

    /** @private {!History} */
    this.history_ = new History(this.unAttach.bind(this));

    /** @private {!Function} */
    this.hideViewer_ = hideViewer;
  }

  /**
   * Attaches the AMP Doc Iframe to the Host Element.
   */
  attach() {
    this.iframe_ = document.createElement('iframe');
    // TODO (chenshay): iframe_.setAttribute('scrolling', 'no')
    // to enable the scrolling workarounds for iOS.

    this.buildIframeSrc_().then(ampDocCachedUrl => {
      this.viewerMessaging_ = new ViewerMessaging(
        window,
        this.iframe_,
        parseUrl(ampDocCachedUrl).origin);

      this.viewerMessaging_.start().then(()=>{
        log('this.viewerMessaging_.start() Promise resolved !!!');
      });

      this.iframe_.src = ampDocCachedUrl;
      this.hostElement_.appendChild(this.iframe_);
      this.history_.pushState(ampDocCachedUrl);
    });
  }

  /**
   * @return {string}
   * @return {!Promise<string>}
   */
  buildIframeSrc_() {
    const parsedViewerUrl = parseUrl(window.location.href);

    // TODO (chenshay): create a place to set all the init params.
    const initParams = {
      origin: parsedViewerUrl.origin
    };
    
    return new Promise(resolve => {
      constructViewerCacheUrl(this.ampDocUrl_, initParams).then(
        viewerCacheUrl => {
          resolve(viewerCacheUrl);
        }
      );
    });
  }

  /**
   * Detaches the AMP Doc Iframe from the Host Element 
   * and calls the hideViewer method.
   */
  unAttach() {
    this.hideViewer_();
    this.hostElement_.removeChild(this.iframe_);
    this.iframe_ = null;
    this.viewerMessaging_ = null;
  }
}
window.Viewer = Viewer;
