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

import {AmpViewerHost} from './amp-viewer-host';

/**
 * This file is a Viewer for AMP Documents. 
 */
class AmpViewer {
 
 /**
  * @param {!Element} hostElement the element to attatch the iframe to.
  * @param {string} ampUrl the AMP page url.
  */
 constructor(hostElement, ampUrl) {
  /** @private {AmpViewerHost} */
  this.viewerHost_ = null;

  /** @private {!Element} */
  this.hostElement_ = hostElement;

  /** @private {string} */
  this.ampUrl_ = ampUrl;

  /** @private {?Element} */
  this.iframe_ = null;
 }

 /**
  * Attaches the AMP Doc Iframe to the Host Element.
  */
 attach() {
   this.iframe_ = document.createElement('iframe');
   this.hostElement_.appendChild(this.iframe_);
   this.iframe_.src = this.ampUrl_;

   this.viewerHost_ = new AmpViewerHost(
     this.hostElement_,
     this.iframe_,
     this.ampUrl_,
     this.requestHandler_,
     /* logs id */ 1);
 }

}
