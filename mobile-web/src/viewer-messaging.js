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

import {
  APP,
  Messaging,
  MessageType,
  RequestHandler,
  WindowPortEmulator,
} from 'amp-viewer-messaging/messaging';
import {log} from '../utils/log';


const CHANNEL_OPEN_MSG = 'channelOpen';

export class ViewerMessaging {

  /**
   * @param {!Window} win
   * @param {!HTMLIFrameElement} ampIframe
   * @param {string} frameOrigin
   * @param {!RequestHandler} messageHandler
   */
  constructor(win, ampIframe, frameOrigin, messageHandler) {
    /** @const {!Window} */
    this.win = win;
    /** @private {!HTMLIFrameElement} */
    this.ampIframe_ = ampIframe;
    /** @private {string} */
    this.frameOrigin_ = frameOrigin;
    /** @private {!RequestHandler} */
    this.messageHandler_ = messageHandler;
  }

  /**
   * @param {boolean=} opt_isHandshakePoll
   * @return {!Promise}
   */
  start(opt_isHandshakePoll) {
    if (opt_isHandshakePoll) {
      /** @private {number} */
      this.pollingIntervalId_ = setInterval(this.initiateHandshake_.bind(
        this, this.intervalCtr) , 1000); //poll every second
      return new Promise(resolve => {
        /** @private {!Function} */
        this.hanshakePollPromiseResolve_ = resolve;
      });
    } else {
      return this.waitForHandshake_(this.frameOrigin_);
    }
  }

  /**
   * @private
   */
  initiateHandshake_() {
    log('initiateHandshake_');
    if (this.ampIframe_) {
      const channel = new MessageChannel();
      let message = {
        app: APP,
        name: 'handshake-poll',
      };
      this.ampIframe_.contentWindow./*OK*/postMessage(
        message, '*', [channel.port2]);

      channel.port1.onmessage = e => {
        const data = e.data;
        if (this.isChannelOpen_(data)) {
          clearInterval(this.pollingIntervalId_); //stop polling
          log('messaging established!');
          this.completeHandshake_(channel.port1, data.requestid).then(() => {
            this.hanshakePollPromiseResolve_();
          });
        } else {
          this.messageHandler_(data.name, data.data, data.rsvp);
        }
      };
    }
  }

  /**
   * @param {string} targetOrigin
   * @return {!Promise}
   * @private
   */
  waitForHandshake_(targetOrigin) {
    log('awaitHandshake_');
    return new Promise(resolve => {
      const listener = e => {
        log('message!', e);
        const target = this.ampIframe_.contentWindow;
        if (e.origin == targetOrigin &&
            this.isChannelOpen_(e.data) &&
            (!e.source || e.source == target)) {
          log(' messaging established with ', targetOrigin);
          this.win.removeEventListener('message', listener);
          const port = new WindowPortEmulator(this.win, targetOrigin, target);
          this.completeHandshake_(port, e.data.requestid).then(() => {
            resolve();
          });
        }
      };
      this.win.addEventListener('message', listener);
    });
  }

  /**
   * @param {!MessagePort|!WindowPortEmulator} port
   * @param {string} requestId
   * @return {!Promise}
   * @private
   */
  completeHandshake_(port, requestId) {
    let message = {
      app: APP,
      requestid: requestId,
      type: MessageType.RESPONSE,
    };

    log('posting Message', message);
    port./*OK*/postMessage(message);

    this.messaging_ = new Messaging(this.win, port);
    this.messaging_.setDefaultHandler(this.messageHandler_);

    this.sendRequest('visibilitychange', {
      state: this.visibilityState_,
      prerenderSize: this.prerenderSize,
    }, true);

    return Promise.resolve();
  };

  /**
   * @param {*} eventData
   * @return {boolean}
   * @private
   */
  isChannelOpen_(eventData) {
    return eventData.app == APP && eventData.name == CHANNEL_OPEN_MSG;
  };

  /**
   * @param {string} type
   * @param {*} data
   * @param {boolean} awaitResponse
   * @return {!Promise<*>|undefined}
   */
  sendRequest(type, data, awaitResponse) {
    log('sendRequest');
    if (!this.messaging_) {
      return;
    }
    return this.messaging_.sendRequest(type, data, awaitResponse);
  };
}
