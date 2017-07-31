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

#import "AMPKWebViewerJsMessage.h"
#import "AMPKWebViewerMessageHandlerController.h"

static NSString *const kAmpJsMessagePostName = @"amp";
static NSString *const kAmpChannelOpenMessageName = @"channelOpen";
static NSString *const kAmpVisibilityChangeMessageName = @"visibilitychange";
static NSString *const kAmpBroadcastMessageName = @"broadcast";

@class AMPKWebViewerBaseMessageHandler;

// Private category to expose setter on origin so handler can pair pending message with origin
// when it receives the reply.
@interface AMPKWebViewerJsMessage (Private)

- (void)setOriginMessage:(AMPKWebViewerJsMessage *)originMessage;

@end

@protocol AMPKWebViewerMessageHandler <NSObject>

- (NSString *)messageName;
- (void)handleAMPMessage:(AMPKWebViewerJsMessage *)message
    forAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController;

@end

@interface AMPKWebViewerBaseMessageHandler : NSObject <AMPKWebViewerMessageHandler>

- (void)addPendingMessage:(AMPKWebViewerJsMessage *)pending;

- (void)cancelPendingMessages;

- (void)handleMessage:(WKScriptMessage *)message
    forAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController;

- (AMPKWebViewerJsMessage *)pendingMessageForOriginMessage:(AMPKWebViewerJsMessage *)origin;

@property(nonatomic, readonly) NSArray *pendingMessages;
@property(nonatomic, weak) AMPKWebViewerMessageHandlerController *controller;

@end

@interface AMPKWebViewerChannelOpenMessageHandler : AMPKWebViewerBaseMessageHandler
@end

@interface AMPKWebViewerDocumentLoadedMessageHandler : AMPKWebViewerBaseMessageHandler
@end

@interface AMPKWebViewerOpenDialogMessageHandler : AMPKWebViewerBaseMessageHandler
@end

@interface AMPKWebViewerBroadcast : AMPKWebViewerBaseMessageHandler
@end

@interface AMPKWebViewerRequestFullOverlay : AMPKWebViewerBaseMessageHandler
@end

@interface AMPKWebViewerCancelFullOverlay : AMPKWebViewerBaseMessageHandler
@end

@interface AMPKWebViewerMessageHandlerController ()
@property(nonatomic, strong)
    NSDictionary<NSString *, AMPKWebViewerBaseMessageHandler *> *messageHandlers;
@property(nonatomic, strong) AMPKWebViewerJsMessage *lastMessage;
@end


@interface AMPKWebViewerMessageHandlerController (Testing)

- (void)startMessageHandlingForWebView:(WKWebView *)webView;
- (void)stopMessageHandlingForWebView:(WKWebView *)webView;
- (BOOL)shouldSendMessage:(AMPKWebViewerJsMessage *)message;
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message;
@end
