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

    /** @private {number} */
    this.currentStateId_ = 0;

    this.init_();
  }

  /**
   * Init the onpopstate listener.
   * @private
   */
  init_() {
    window.addEventListener('popstate', event => {
      const state = event.state;
      if (!state) {
        this.decreaseCurrentStateId();
        this.handleChangeHistoryState_(true /* isBack */, true /* isLastBack */, null);
        return;
      }

      const poppedStateId = (typeof state.stateId !== 'undefined') ? state.stateId : null;
      const poppedStackIndex = (typeof state.stackIndex !== 'undefined') ? state.stackIndex : null;

      const isBack = this.isBack_(poppedStateId);
      if (isBack) {
        this.decreaseCurrentStateId();
      } else {
        this.increaseCurrentStateId();
      }
      this.handleChangeHistoryState_(isBack, false /* isLastBack */, poppedStackIndex);
    });
  }

  /**
   * Updates the history state.
   */
  decreaseCurrentStateId() {
    this.currentStateId_--;
  }

  /**
   * Updates the history state.
   */
  increaseCurrentStateId() {
    this.currentStateId_++;
  }

  /**
   * @param {number} poppedStateId id of the popped history state.
   * @return {boolean} true if back button was hit.
   * @private
   */
  isBack_(poppedStateId) {
    return this.currentStateId_ > poppedStateId;
  }

  /**
   * Init the onpopstate listener.
   * @param {string} url The url to push onto the Viewer history.
   * @param {object} opt_data
   */
  pushState(url, opt_data) {
    this.increaseCurrentStateId();
    let stateData = {
      urlPath: url,
      stateId: this.currentStateId_ // id of the current history state.
    };
    if (opt_data && typeof opt_data.stackIndex !== 'undefined') {
      // history index that the AMP doc uses.
      stateData.stackIndex = opt_data.stackIndex;
    } 

    // The url should have /amp/ + url added to it. For example:
    // example.com -> example.com/amp/https://www.ampproject.org
    const urlStr = '/amp/' + url;
    window.history.pushState(stateData, '', urlStr);
  }

  /**
   * Pop the history state.
   */
  popState() {
    window.history.back();
  }
}
