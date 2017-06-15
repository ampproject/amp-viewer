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
   * @param {!Function} handleLastPop what to do on last Viewer history pop.
   * @param {boolean} opt_enableHistoryFragment
   */
  constructor(handleLastPop, opt_enableHistoryFragment) {
    /** @private {!Array<string>} */
    this.stack_ = [];

    /** @private {!Function} */
    this.handleLastPop_ = handleLastPop;

    /** @private {boolean} */
    this.enableHistoryFragment_ = !!opt_enableHistoryFragment;

    this.init_();
  }

  /**
   * Init the onpopstate listener.
   * @private
   */
  init_() {
    window.onpopstate = event => {
      const popped = this.stack_.pop();
      // If we're at the last Viewer history pop.
      if (popped && !this.stack_.length) {
        this.handleLastPop_();
      }
    };
  }

  /**
   * Init the onpopstate listener.
   * @param {string} url The url to push onto the Viewer history.
   */
  pushState(url) {
    this.stack_.push(url);
    const urlStr = this.enableHistoryFragment_ ? '#ampf=' + url : '#' + url;
    window.history.pushState({urlPath: url}, '', urlStr);
  }
}
