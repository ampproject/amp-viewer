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

#import "AMPKWebViewerMessageHandlerController.h"

#import "AMPKBroadcastWatcher.h"
#import "AMPKDefines.h"
#import "AMPKMessageBroadcaster.h"
#import "AMPKPresenterProtocol.h"
#import "AMPKWebViewerJsMessage.h"
#import "AMPKWebViewerMessageHandlerController_private.h"
#import "AMPKWebViewerViewController.h"
#import "AMPKWebViewerViewController_private.h"

typedef NS_ENUM(NSInteger, AMPKVisibilityState) {
  AMPKVisibilityStatePrefetched,
  AMPKVisibilityStateVisible,
  AMPKVisibilityStateHidden,
};

static NSString * const AMPKJSBundle = @"AmpKit.bundle";
static NSString * const AMPKJSName = @"amp_integration";
static NSString * const AMPKJSExtension = @"js";

static NSString *AMPKLoadAmpIntegrationSource(void) {
  static dispatch_once_t onceToken;
  static NSString *jsContents;
  dispatch_once(&onceToken, ^{
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"AMPKit" ofType:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    NSString *resourcePath = [bundle pathForResource:AMPKJSName ofType:AMPKJSExtension];
    NSError *error;

    jsContents = [[NSString alloc] initWithContentsOfFile:resourcePath
                                                 encoding:NSUTF8StringEncoding
                                                    error:&error];
    if (error) {
      NSLog(@"Error reading AMPKit integration script from the Bundle\n%@\n",error);
    }
  });
  return jsContents;
};

static NSDictionary *kAMPKVisibilityState(void) {
  return @{ @(AMPKVisibilityStateVisible) : @"visible",
            @(AMPKVisibilityStateHidden) : @"inactive",
            @(AMPKVisibilityStatePrefetched) : @"prerender" };
}

@implementation AMPKWebViewerMessageHandlerController {
  WKUserScript *_ampIntegrationScript;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSMutableDictionary *handlers = [NSMutableDictionary dictionary];

    void (^addEntry)(Class) = ^(Class class) {
      AMPKWebViewerBaseMessageHandler *handler = [[class alloc] init];
      handlers[handler.messageName] = handler;
      handler.controller = self;
    };
    addEntry([AMPKWebViewerChannelOpenMessageHandler class]);
    addEntry([AMPKWebViewerDocumentLoadedMessageHandler class]);
    addEntry([AMPKWebViewerOpenDialogMessageHandler class]);
    addEntry([AMPKWebViewerBroadcast class]);
    addEntry([AMPKWebViewerRequestFullOverlay class]);
    addEntry([AMPKWebViewerCancelFullOverlay class]);

    _messageHandlers = [handlers copy];

    _ampIntegrationScript =
        [[WKUserScript alloc] initWithSource:AMPKLoadAmpIntegrationSource()
                               injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                            forMainFrameOnly:NO];
  }
  return self;
}

#pragma mark - Public

- (void)setAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController {
  if (ampWebViewerController) {
    [self startMessageHandlingForWebView:ampWebViewerController.webView];
  } else {
    [self stopMessageHandlingForWebView:_ampWebViewerController.webView];
  }
  _ampWebViewerController = ampWebViewerController;
}

- (void)startMessageHandlingForWebView:(WKWebView *)webView {
  [self stopMessageHandlingForWebView:webView];

  [webView.configuration.userContentController addScriptMessageHandler:self
                                                                  name:kAmpJsMessagePostName];
  [webView.configuration.userContentController addUserScript:_ampIntegrationScript];
}

- (void)stopMessageHandlingForWebView:(WKWebView *)webView {
  [webView.configuration.userContentController
      removeScriptMessageHandlerForName:kAmpJsMessagePostName];
  [webView.configuration.userContentController removeAllUserScripts];
}

- (void)cancelPendingMessages {
  [_messageHandlers
       enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                           AMPKWebViewerBaseMessageHandler * _Nonnull obj,
                                           BOOL * _Nonnull stop) {
         [obj cancelPendingMessages];
  }];
}

- (void)sendAmpJsMessage:(AMPKWebViewerJsMessage *)message{
  // Until the documentLoaded message has been received, we should not send any messages to the
  // document unless it is a visibilitychange message
  __weak WKWebView *weakWebview = self.ampWebViewerController.webView;
  if ([self shouldSendMessage:message]) {
    static NSString *const kAmpCommunicationFunctionFormat =
        @"gws.amp.doc.messaging.receiveMessage(%@);";

    AMPKWebViewerJsResponse checkJsExecutionBlock = ^(NSString *result, NSError *error) {
      __unused WKWebView *strongWebView = weakWebview;
      // If the webview has been deallocated, the message will always fail. However, we don't care
      // about failed messages in this case because the webview is gone, meaning any state the
      // runtime was in is now irrelevant.
      NSAssert((strongWebView && error == nil) || (!strongWebView),
                 @"sent \"%@\" message to JS and got error: %@", message, error);

      if (message.jsResponse) {
        message.jsResponse(result, error);
      }
    };

    NSString *jsonMessageExecution =
        [NSString stringWithFormat:kAmpCommunicationFunctionFormat, [message jsonString]];

    WKWebView *webView = self.ampWebViewerController.webView;

    [webView evaluateJavaScript:jsonMessageExecution completionHandler:checkJsExecutionBlock];
  }
}

- (void)sendVisible:(BOOL)visible{
  // Until some message has been received, we could not have received the document loaded message.
  // Therefore, don't even bother creating the message and requesting it be sent as it will not.
  if (!_lastMessage) {
    return;
  }
  AMPKVisibilityState state = visible ? AMPKVisibilityStateVisible : AMPKVisibilityStateHidden;
  [self sendVisibilityState:state];
}

- (void)sendPrefetched {
  // Until some message has been received, we could not have received the document loaded message.
  // Therefore, don't even bother creating the message and requesting it be sent as it will not.
  if (!_lastMessage) {
    return;
  }
  [self sendVisibilityState:AMPKVisibilityStatePrefetched];
}

- (void)sendVisibilityState:(AMPKVisibilityState)visibilityState {
  NSString *state = kAMPKVisibilityState()[@(visibilityState)];
  AMPKWebViewerJsMessage *message =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpVisibilityChangeMessageName
                                    channelID:_lastMessage.channelID
                                    requestID:_lastMessage.requestID + 1
                             responseRequired:NO
                                         data:@{@"prerenderSize" : @(1), @"state" : state}
                                originMessage:nil
                                        error:nil];

  [self sendAmpJsMessage:message];

}

- (void)forwardBroadcast:(AMPKWebViewerJsMessage *)broadcast{
  AMPKWebViewerJsMessage *forward =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpBroadcastMessageName
                                    channelID:_lastMessage.channelID
                                    requestID:_lastMessage.requestID + 1
                             responseRequired:broadcast.rsvp
                                         data:broadcast.data
                                originMessage:broadcast
                                        error:nil];
  [self sendAmpJsMessage:forward];
}
#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
  // Check the message host matches with current URL host.
  if ([_sourceHostName isEqualToString:message.frameInfo.request.URL.host]) {
    AMPKWebViewerJsMessage *ampMessage = [message ampWebViewerJsMessage];
    AMPKWebViewerBaseMessageHandler *handler = self.messageHandlers[ampMessage.name];
    [handler handleMessage:message forAmpWebViewerController:self.ampWebViewerController];
    AMPKMessageType type = [AMPKWebViewerJsMessage messageTypeForString:ampMessage.type];
    if (type == AMPKMessageTypeRequest) {
      _lastMessage = ampMessage;
    }
  }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
  WKNavigationActionPolicy policy = WKNavigationActionPolicyAllow;

  // User taps on embedded link.
  NSString *urlScheme = [navigationAction.request.URL.scheme lowercaseString];
  if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
    if ([urlScheme isEqualToString:@"http"] || [urlScheme isEqualToString:@"https"]) {
      id<AMPKPresenterProtocol> presenter = self.ampWebViewerController.presenter;
      [presenter presentEmbeddedLinkRequest:navigationAction.request
                         fromViewController:self.ampWebViewerController];
    } else {
      [UIApplication.sharedApplication openURL:navigationAction.request.URL];
    }
    policy = WKNavigationActionPolicyCancel;
  }

  decisionHandler(policy);
}

#pragma mark - Private Methods

- (BOOL)shouldSendMessage:(AMPKWebViewerJsMessage *)message {
  if (self.ampWebViewerController.ampJsReady ||
      [[message name] isEqualToString:kAmpChannelOpenMessageName]) {
    AMPKWebViewerBaseMessageHandler *handler = _messageHandlers[message.name];
    AMPKMessageType type = [AMPKWebViewerJsMessage messageTypeForString:[message type]];
    if (type == AMPKMessageTypeResponse) {
      message.originMessage = [handler pendingMessageForOriginMessage:message];
    } else {
      if ([message rsvp]) {
       [handler addPendingMessage:message];
      }
      _lastMessage = message;
    }
    return YES;
  }

  return NO;
}

@end

// Base class for message handler. Handles storing pending messages and pairing them with origin
// when received. Receives the raw WKScriptMessage and forwards AMP message to actual message
// handler.
@implementation AMPKWebViewerBaseMessageHandler {
  NSMutableArray <AMPKWebViewerJsMessage *> * _pending;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _pending = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)handleMessage:(WKScriptMessage *)message
    forAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController {
  AMPKWebViewerJsMessage *ampMessage = [message ampWebViewerJsMessage];
  if (ampMessage) {
    AMPKMessageType type = [AMPKWebViewerJsMessage messageTypeForString:[ampMessage type]];
    if (type == AMPKMessageTypeRequest && [ampMessage rsvp]) {
      [_pending addObject:ampMessage];
    } else if (type == AMPKMessageTypeResponse) {
      ampMessage.originMessage = [self pendingMessageForOriginMessage:ampMessage];
    }

    [self handleAMPMessage:ampMessage forAmpWebViewerController:ampWebViewerController];
  }
}

// Store message when it is sent and requests and RSVP.
- (void)addPendingMessage:(AMPKWebViewerJsMessage *)pending {
  [_pending addObject:pending];
}

// In the base case, pending messages can be ignored.
- (void)cancelPendingMessages{
  [_pending removeAllObjects];
}

- (NSString *)messageName {
  AMPKitAssertAbstractMethod();
  return @"";
}

- (AMPKWebViewerJsMessage *)pendingMessageForOriginMessage:(AMPKWebViewerJsMessage *)origin {
  AMPKWebViewerJsMessage *pending;
  NSInteger index =
  [_pending indexOfObjectPassingTest:^BOOL(AMPKWebViewerJsMessage * _Nonnull obj,
                                           NSUInteger idx,
                                           BOOL * _Nonnull stop) {
    if ([obj requestID] == [origin requestID] && [obj channelID] == [origin channelID]) {
      *stop = YES;
      return YES;
    }
    return NO;
  }];
  if (index != NSNotFound) {

    pending = _pending[index];
    [_pending removeObjectAtIndex:index];
  }
  return pending;
}

// Method that all message handlers should implement. This will be called when a message has been
// received from the WKWebview.
- (void)handleAMPMessage:(AMPKWebViewerJsMessage *)message
    forAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController {
  AMPKitAssertAbstractMethod();
}

- (NSArray *)pendingMessages {
  return [_pending copy];
}

@end

@implementation AMPKWebViewerOpenDialogMessageHandler

- (NSString *)messageName {
  return @"openDialog";
}

- (void)handleAMPMessage:(AMPKWebViewerJsMessage *)ampMessage
    forAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController {
  // TODO:(stephen-deg) Implement correctly in AMPKit
}

@end

@implementation AMPKWebViewerChannelOpenMessageHandler

- (NSString *)messageName {
  return kAmpChannelOpenMessageName;
}

- (void)handleAMPMessage:(AMPKWebViewerJsMessage *)ampMessage
    forAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController {
    [ampWebViewerController channelOpenWithMessage:ampMessage];
}

@end

@implementation AMPKWebViewerDocumentLoadedMessageHandler

- (NSString *)messageName {
  return @"documentLoaded";
}

- (void)handleAMPMessage:(AMPKWebViewerJsMessage *)ampMessage
    forAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController {
    [ampWebViewerController AMPDocumentLoadedWithMessage:ampMessage];
}

@end

@implementation AMPKWebViewerBroadcast

- (NSString *)messageName {
  return kAmpBroadcastMessageName;
}

// Whenever a broadcast message is received, we post a notification so that the data source can
// track this broadcast as either a new broadcast to forward or as a reply to a pending broadcast.
- (void)handleAMPMessage:(AMPKWebViewerJsMessage *)ampMessage
    forAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController {
    [self.controller.ampMessageBroadcaster postBroadcast:ampMessage fromController:self.controller];
}

// Whenever a broadcast message is cancelled, we must notify the origin of the cancellation so it
// can stop waiting for a reply.
- (void)cancelPendingMessages {
  for (AMPKWebViewerJsMessage *message in self.pendingMessages) {
    [self.controller.ampMessageBroadcaster cancelBroadcast:message forController:self.controller];
  }

  [super cancelPendingMessages];
}

@end

@implementation AMPKWebViewerRequestFullOverlay

- (NSString *)messageName {
  return @"requestFullOverlay";
}

- (void)handleAMPMessage:(AMPKWebViewerJsMessage *)ampMessage
    forAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController {
    [self.controller.ampWebViewerController requestFullOverlayMode];
}

@end

@implementation AMPKWebViewerCancelFullOverlay

- (NSString *)messageName {
  return @"cancelFullOverlay";
}

- (void)handleAMPMessage:(AMPKWebViewerJsMessage *)ampMessage
    forAmpWebViewerController:(AMPKWebViewerViewController *)ampWebViewerController {
    [self.controller.ampWebViewerController cancelFullOverlayMode];
}

@end
