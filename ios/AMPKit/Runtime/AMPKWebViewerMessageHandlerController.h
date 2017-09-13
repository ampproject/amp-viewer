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

#import <WebKit/WebKit.h>

@class AMPKMessageBroadcaster;
@class AMPKWebViewerJsMessage;
@class AMPKWebViewerViewController;

/** A controller that handles all the communication between AMP JS and AMP viewer. */
@interface AMPKWebViewerMessageHandlerController : NSObject <WKScriptMessageHandler,
                                                             WKNavigationDelegate>

@property(nonatomic, weak) AMPKWebViewerViewController *ampWebViewerController;
@property(nonatomic, weak) AMPKMessageBroadcaster *ampMessageBroadcaster;
@property(nonatomic, copy) NSURL *source;

/** Send AMP page message via AMP JS channel. */
- (void)sendAmpJsMessage:(AMPKWebViewerJsMessage *)message;

/** Send a visibility state message to the webview. */
- (void)sendVisible:(BOOL)visible;

/** Forward a broadcast message from some other webview to this webview. */
- (void)forwardBroadcast:(AMPKWebViewerJsMessage *)broadcast;

/** Cancels all the currently pending messages for all message handlers. */
- (void)cancelPendingMessages;

@end
