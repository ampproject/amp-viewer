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

import {log} from '../utils/log';

/**
 * This file manages history for the Viewer.
 */
export class History {
  /** 
   * @param {!Function} handleChangeHistoryState what to do when the history
   *  state changes.
   */
  constructor(handleChangeHistoryState) {
    /** @private {!Function} */
    this.handleChangeHistoryState_ = handleChangeHistoryState;

    this.init_();
  }

  /**
   * Init the onpopstate listener.
   * @private
   */
  init_() {
    window.addEventListener('popstate', event => {
      const urlPath = event.state ? event.state.urlPath : null;
      this.handleChangeHistoryState_(urlPath);
    });
  }

  /**
   * Init the onpopstate listener.
   * @param {string} url The url to push onto the Viewer history.
   */
  pushState(url) {
    const urlStr = '/amp/' + url;
    window.history.pushState({urlPath: url}, '', urlStr);
  }
}
