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

#import <Foundation/Foundation.h>

@class AMPKWebViewerJsMessage;
@class AMPKWebViewerMessageHandlerController;
@class AMPKWebViewerViewController;

/**
 * A lightweight class that tracks broadcast messages with RSVP requested. Tracks which webviews
 * have pending replies and then tracks received replies and sends reply to origin message when all
 * replies have been received.
 */
@interface AMPKBroadcastWatcher : NSObject

/** Indicates if all webviews which were forwarded to have either completed or cancelled. */
@property(nonatomic, readonly) BOOL completed;

/**
 * Indicates that there is at least one webview that has been forwarded a broadcast which the reply
 * has yet to be received.
 */
@property(nonatomic, readonly) BOOL pending;

/**
 * Designated initializer which is passed the origin message to track and the webview associated
 * with this message.
 */
- (instancetype)initWithOriginBroadcast:(__weak AMPKWebViewerJsMessage *)origin
               forDestinationController:
    (__weak AMPKWebViewerMessageHandlerController *)controller;

/** Should be called when a new webview needs to be forwarded the broadcast message. */
- (void)forwardMessageToController:(AMPKWebViewerMessageHandlerController *)controller;

/** Called when a reponse has been received from one of the webviews which was forwarded a
 * broadcast.
 */
- (void)receiveMessage:(AMPKWebViewerJsMessage *)response
        fromController:(AMPKWebViewerMessageHandlerController *)controller;

/**
 * Called when a webview has indicated that its pending reply has been cancelled and a response will
 * not be received. The watcher will no longer wait for this reply before sending the final reply to
 * the origin.
 */
- (void)cancelMessageFromController:(AMPKWebViewerMessageHandlerController *)controller;

/** Should be called when the origin has been cancelled and a reply does not need to be sent. */
- (void)cancel;

@end
