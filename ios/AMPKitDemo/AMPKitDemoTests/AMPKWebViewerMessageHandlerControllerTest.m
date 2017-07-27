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

#import <XCTest/XCTest.h>

#import "AMPKWebViewerJsMessage_private.h"
#import "AMPKWebViewerMessageHandlerController_private.h"
#import "AMPKTestHelper.h"
#import "AMPKWebViewerViewController.h"
#import "AMPKWebViewerViewController_private.h"

#import <OCMock/OCMock.h>

@interface AMPKWebViewerMessageHandlerControllerTest : XCTestCase

@property(nonatomic, strong) AMPKWebViewerMessageHandlerController *messageHandlerController;

@end

@implementation AMPKWebViewerMessageHandlerControllerTest

- (void)setUp {
  [super setUp];
  self.messageHandlerController = [[AMPKWebViewerMessageHandlerController alloc] init];
  self.messageHandlerController.sourceHostName = kAmpKitTestSourceHostName;
}

- (void)tearDown {
  self.messageHandlerController = nil;
  [super tearDown];
}

- (void)testReceiveMessageMismatchingHost {
  id mockWKScriptMessage = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                                 name:@"irrelevant"
                                                            channelID:0
                                                            requestID:0
                                                                 RSVP:NO
                                                                 data:nil
                                                                error:nil];

  self.messageHandlerController.sourceHostName = @"nope.com";

  [self.messageHandlerController userContentController:[WKUserContentController new]
                               didReceiveScriptMessage:mockWKScriptMessage];

  XCTAssertNil(self.messageHandlerController.lastMessage);
}

- (void)testSaveLastMessage {
  id mockWKScriptMessage = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                                 name:@"irrelevant"
                                                            channelID:0
                                                            requestID:0
                                                                 RSVP:NO
                                                                 data:nil
                                                                error:nil];

  [self.messageHandlerController userContentController:[WKUserContentController new]
                               didReceiveScriptMessage:mockWKScriptMessage];

  AMPKWebViewerJsMessage *message = [mockWKScriptMessage ampWebViewerJsMessage];

  XCTAssertEqualObjects(self.messageHandlerController.lastMessage, message);
}

- (void)testSendVisible {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  self.messageHandlerController.ampWebViewerController = ampViewer;

  id messageHandlerControllerMock =
      OCMPartialMock(self.messageHandlerController);

  id webViewMock = OCMPartialMock(ampViewer.webView);

  [[webViewMock expect] evaluateJavaScript:[OCMArg isNotNil] completionHandler:[OCMArg isNotNil]];

  id testDocLoaded = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                           name:@"documentLoaded"
                                                      channelID:0
                                                      requestID:0
                                                           RSVP:NO
                                                           data:nil
                                                          error:nil];

  [self.messageHandlerController userContentController:nil
                               didReceiveScriptMessage:testDocLoaded];

  [messageHandlerControllerMock sendVisible:YES];

  [webViewMock verify];
  [webViewMock stopMocking];
}

- (void)testVisibleMessageValueTrue {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  self.messageHandlerController.ampWebViewerController = ampViewer;

  id messageHandlerControllerMock =
      OCMPartialMock(self.messageHandlerController);

  [[messageHandlerControllerMock expect] sendAmpJsMessage:[OCMArg checkWithBlock:^BOOL(id obj) {
    AMPKWebViewerJsMessage *message = (AMPKWebViewerJsMessage *)obj;
    NSDictionary *data = [message data];
    NSString *visibleState = data[@"state"];
    if (visibleState && [visibleState isEqualToString:@"visible"]) {
      return YES;
    }
    return NO;
  }]];

  id testDocLoaded = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                           name:@"documentLoaded"
                                                      channelID:0
                                                      requestID:0
                                                           RSVP:NO
                                                           data:nil
                                                          error:nil];

  [self.messageHandlerController userContentController:nil
                               didReceiveScriptMessage:testDocLoaded];

  [self.messageHandlerController sendVisible:YES];

  [messageHandlerControllerMock verify];
  [messageHandlerControllerMock stopMocking];
}

- (void)testVisibleMessageValueFalse {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  self.messageHandlerController.ampWebViewerController = ampViewer;

  id messageHandlerControllerMock =
      OCMPartialMock(self.messageHandlerController);

  [[messageHandlerControllerMock expect] sendAmpJsMessage:[OCMArg checkWithBlock:^BOOL(id obj) {
    AMPKWebViewerJsMessage *message = (AMPKWebViewerJsMessage *)obj;
    NSDictionary *data = [message data];
    NSString *visibleState = data[@"state"];
    if (visibleState && [visibleState isEqualToString:@"inactive"]) {
      return YES;
    }
    return NO;
  }]];

  id testDocLoaded = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                           name:@"documentLoaded"
                                                      channelID:0
                                                      requestID:0
                                                           RSVP:NO
                                                           data:nil
                                                          error:nil];

  [self.messageHandlerController userContentController:nil
                               didReceiveScriptMessage:testDocLoaded];

  [self.messageHandlerController sendVisible:NO];

  [messageHandlerControllerMock verify];
  [messageHandlerControllerMock stopMocking];
}

- (void)testSendVisibleTooEarly {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  self.messageHandlerController.ampWebViewerController = ampViewer;

  id messageHandlerControllerMock =
      OCMPartialMock(self.messageHandlerController);

  id webViewMock = OCMPartialMock(ampViewer.webView);

  [[webViewMock expect] evaluateJavaScript:[OCMArg isNotNil] completionHandler:[OCMArg isNotNil]];

  [messageHandlerControllerMock sendVisible:YES];

  XCTAssertThrows([webViewMock verify]);
  [webViewMock stopMocking];
}

- (void)testDocumentLoadedPreparesAmpViewer {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];
  id ampViewerMock = OCMPartialMock(ampViewer);
  self.messageHandlerController.ampWebViewerController = ampViewerMock;
  [[ampViewerMock expect] AMPDocumentLoadedWithMessage:[OCMArg isNotNil]];

  id testDocLoaded = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                           name:@"documentLoaded"
                                                      channelID:0
                                                      requestID:0
                                                           RSVP:NO
                                                           data:nil
                                                          error:nil];

  [self.messageHandlerController userContentController:nil
                               didReceiveScriptMessage:testDocLoaded];
  [ampViewerMock verify];
  [ampViewerMock stopMocking];
}

- (void)testStartHandlingMessagesForWebView {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  XCTAssertNotNil(ampViewer.webView);
  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 0);

  [self.messageHandlerController setAmpWebViewerController:ampViewer];

  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 1);
}

- (void)testStopHandlingMessagesForWebView {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];
  XCTAssertNotNil(ampViewer.webView);
  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 0);

  [self.messageHandlerController setAmpWebViewerController:ampViewer];

  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 1);

  [self.messageHandlerController setAmpWebViewerController:nil];
  XCTAssertNotNil(ampViewer.webView);
  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 0);
}

- (void)testStopHandlingMessagesForWebViewBeforeStart {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  XCTAssertNotNil(ampViewer.webView);
  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 0);

  XCTAssertNoThrow([self.messageHandlerController stopMessageHandlingForWebView:ampViewer.webView]);

  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 0);
}

- (void)testStopHandlingMessagesForWebViewAfterStop {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  XCTAssertNotNil(ampViewer.webView);
  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 0);

  [self.messageHandlerController setAmpWebViewerController:ampViewer];

  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 1);

  [self.messageHandlerController setAmpWebViewerController:nil];
  XCTAssertNotNil(ampViewer.webView);
  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 0);

  XCTAssertNoThrow([self.messageHandlerController stopMessageHandlingForWebView:ampViewer.webView]);
  XCTAssertNotNil(ampViewer.webView);
  XCTAssertEqual(ampViewer.webView.configuration.userContentController.userScripts.count, 0);
}

- (void)testShouldSendArbitraryMessage {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];
  [self.messageHandlerController setAmpWebViewerController:ampViewer];
  [ampViewer AMPDocumentLoadedWithMessage:nil];

  id jsMessageMock = OCMClassMock([AMPKWebViewerJsMessage class]);
  [[[jsMessageMock stub] andReturn:kAmpChannelOpenMessageName] name];
  [(AMPKWebViewerJsMessage *)[[jsMessageMock stub] andReturn:kAmpMessageRequest] type];

  XCTAssertTrue([self.messageHandlerController shouldSendMessage:jsMessageMock]);
}

- (void)testShouldAddPendingMessage {
  id jsMessageMock = OCMClassMock([AMPKWebViewerJsMessage class]);
  [[[jsMessageMock stub] andReturn:kAmpChannelOpenMessageName] name];
  [(AMPKWebViewerJsMessage *)[[jsMessageMock stub] andReturn:kAmpMessageRequest] type];
  [(AMPKWebViewerJsMessage *)[[jsMessageMock stub] andReturnValue:@(YES)] rsvp];

  AMPKWebViewerBaseMessageHandler *handler =
      self.messageHandlerController.messageHandlers[[jsMessageMock name]];

  XCTAssertEqual(handler.pendingMessages.count, 0);
  [self.messageHandlerController shouldSendMessage:jsMessageMock];
  XCTAssertEqual(handler.pendingMessages.count, 1);
}

- (void)testShouldNotAddPendingMessage {
  id jsMessageMock = OCMClassMock([AMPKWebViewerJsMessage class]);
  [[[jsMessageMock stub] andReturn:kAmpChannelOpenMessageName] name];
  [(AMPKWebViewerJsMessage *)[[jsMessageMock stub] andReturn:kAmpMessageRequest] type];
  [(AMPKWebViewerJsMessage *)[[jsMessageMock stub] andReturnValue:@(NO)] rsvp];

  AMPKWebViewerBaseMessageHandler *handler =
      self.messageHandlerController.messageHandlers[[jsMessageMock name]];

  XCTAssertEqual(handler.pendingMessages.count, 0);
  [self.messageHandlerController shouldSendMessage:jsMessageMock];
  XCTAssertEqual(handler.pendingMessages.count, 0);
}

- (void)testShouldMatchReply {
  AMPKWebViewerJsMessage *message =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpChannelOpenMessageName
                                    channelID:0
                                    requestID:3
                             responseRequired:YES
                                         data:nil
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerBaseMessageHandler *handler =
      self.messageHandlerController.messageHandlers[[message name]];

  XCTAssertEqual(handler.pendingMessages.count, 0);
  [self.messageHandlerController shouldSendMessage:message];
  XCTAssertEqual(handler.pendingMessages.count, 1);

  id mockWKScriptMessage =
      [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeResponse
                                            name:kAmpChannelOpenMessageName
                                       channelID:0
                                       requestID:3
                                            RSVP:NO
                                            data:nil
                                           error:nil];

  [self.messageHandlerController userContentController:[WKUserContentController new]
                               didReceiveScriptMessage:mockWKScriptMessage];

  XCTAssertEqual(handler.pendingMessages.count, 0);
}

- (void)testReplyDoesNotMatchName {
  AMPKWebViewerJsMessage *message =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpChannelOpenMessageName
                                    channelID:0
                                    requestID:3
                             responseRequired:YES
                                         data:nil
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerBaseMessageHandler *handler =
      self.messageHandlerController.messageHandlers[[message name]];

  XCTAssertEqual(handler.pendingMessages.count, 0);
  [self.messageHandlerController shouldSendMessage:message];
  XCTAssertEqual(handler.pendingMessages.count, 1);

  id mockWKScriptMessage =
      [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeResponse
                                            name:@"nope"
                                       channelID:0
                                       requestID:3
                                            RSVP:NO
                                            data:nil
                                           error:nil];

  [self.messageHandlerController userContentController:[WKUserContentController new]
                               didReceiveScriptMessage:mockWKScriptMessage];

  XCTAssertNotEqual(handler.pendingMessages.count, 0);
}

- (void)testReplyDoesNotMatchChannel {
  AMPKWebViewerJsMessage *message =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpChannelOpenMessageName
                                    channelID:0
                                    requestID:3
                             responseRequired:YES
                                         data:nil
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerBaseMessageHandler *handler =
      self.messageHandlerController.messageHandlers[[message name]];

  XCTAssertEqual(handler.pendingMessages.count, 0);
  [self.messageHandlerController shouldSendMessage:message];
  XCTAssertEqual(handler.pendingMessages.count, 1);

  id mockWKScriptMessage =
      [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeResponse
                                            name:kAmpChannelOpenMessageName
                                       channelID:1
                                       requestID:3
                                            RSVP:NO
                                            data:nil
                                           error:nil];

  [self.messageHandlerController userContentController:[WKUserContentController new]
                               didReceiveScriptMessage:mockWKScriptMessage];

  XCTAssertNotEqual(handler.pendingMessages.count, 0);
}

- (void)testReplyDoesNotMatchResponseId {
  AMPKWebViewerJsMessage *message =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpChannelOpenMessageName
                                    channelID:0
                                    requestID:3
                             responseRequired:YES
                                         data:nil
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerBaseMessageHandler *handler =
      self.messageHandlerController.messageHandlers[[message name]];

  XCTAssertEqual(handler.pendingMessages.count, 0);
  [self.messageHandlerController shouldSendMessage:message];
  XCTAssertEqual(handler.pendingMessages.count, 1);

  id mockWKScriptMessage =
      [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeResponse
                                            name:kAmpChannelOpenMessageName
                                       channelID:0
                                       requestID:4
                                            RSVP:NO
                                            data:nil
                                           error:nil];

  [self.messageHandlerController userContentController:[WKUserContentController new]
                               didReceiveScriptMessage:mockWKScriptMessage];

  XCTAssertNotEqual(handler.pendingMessages.count, 0);
}

- (void)testRespondingToChannelOpen {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];
  self.messageHandlerController.ampWebViewerController = ampViewer;
  id mockAmpViewer = OCMPartialMock(ampViewer);
  id mockChannelOpenIncomingMessage =
      [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                            name:kAmpChannelOpenMessageName
                                       channelID:0
                                       requestID:0
                                            RSVP:YES
                                            data:nil
                                           error:nil];
  AMPKWebViewerJsMessage *incomingChannelOpenJsMessage =
      [mockChannelOpenIncomingMessage ampWebViewerJsMessage];
  [[mockAmpViewer expect] channelOpenWithMessage:incomingChannelOpenJsMessage];
  [self.messageHandlerController userContentController:nil
                               didReceiveScriptMessage:mockChannelOpenIncomingMessage];
  [mockAmpViewer verify];
}

- (void)testIncreasingRequestIdValue {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  self.messageHandlerController.ampWebViewerController = ampViewer;

  id messageHandlerControllerMock =
      OCMPartialMock(self.messageHandlerController);

  [[messageHandlerControllerMock expect] sendAmpJsMessage:[OCMArg checkWithBlock:^BOOL(id obj) {
    AMPKWebViewerJsMessage *message = (AMPKWebViewerJsMessage *)obj;
    if (message.requestID == 1) {
      return YES;
    }
    return NO;
  }]];

  id testDocLoaded = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                           name:@"documentLoaded"
                                                      channelID:0
                                                      requestID:0
                                                           RSVP:NO
                                                           data:nil
                                                          error:nil];

  [self.messageHandlerController userContentController:nil
                               didReceiveScriptMessage:testDocLoaded];

  [self.messageHandlerController sendVisible:YES];

  [messageHandlerControllerMock verify];
  [messageHandlerControllerMock stopMocking];

}

- (void)testIncreasingRequestIdValueMultipleTimes {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];
  __block NSInteger expectedrequestID = 1;

  self.messageHandlerController.ampWebViewerController = ampViewer;

  id messageHandlerControllerMock =
      OCMPartialMock(self.messageHandlerController);

  id expectArgument = [OCMArg checkWithBlock:^BOOL(id obj) {
    AMPKWebViewerJsMessage *message = (AMPKWebViewerJsMessage *)obj;
    if (message.requestID == expectedrequestID) {
      return YES;
    }
    return NO;
  }];

  [[[messageHandlerControllerMock expect] andForwardToRealObject] sendAmpJsMessage:expectArgument];


  id testDocLoaded = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                           name:@"documentLoaded"
                                                      channelID:0
                                                      requestID:0
                                                           RSVP:NO
                                                           data:nil
                                                          error:nil];

  [self.messageHandlerController userContentController:nil
                               didReceiveScriptMessage:testDocLoaded];

  [self.messageHandlerController sendVisible:YES];

  expectedrequestID = 2;

  [[[messageHandlerControllerMock expect] andForwardToRealObject] sendAmpJsMessage:expectArgument];

  [self.messageHandlerController sendVisible:NO];

  [messageHandlerControllerMock verify];
}

- (void)testCorrectChannelIdValue {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  self.messageHandlerController.ampWebViewerController = ampViewer;

  id messageHandlerControllerMock =
      OCMPartialMock(self.messageHandlerController);

  [[messageHandlerControllerMock expect] sendAmpJsMessage:[OCMArg checkWithBlock:^BOOL(id obj) {
    AMPKWebViewerJsMessage *message = (AMPKWebViewerJsMessage *)obj;
    if (message.channelID == 0) {
      return YES;
    }
    return NO;
  }]];

  id testDocLoaded = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                           name:@"documentLoaded"
                                                      channelID:0
                                                      requestID:0
                                                           RSVP:NO
                                                           data:nil
                                                          error:nil];

  [self.messageHandlerController userContentController:nil
                               didReceiveScriptMessage:testDocLoaded];

  [self.messageHandlerController sendVisible:YES];

  [messageHandlerControllerMock verify];
  [messageHandlerControllerMock stopMocking];
}

- (void)testShouldSendChannelOpen {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];
  [self.messageHandlerController setAmpWebViewerController:ampViewer];

  id jsMessageMock = OCMClassMock([AMPKWebViewerJsMessage class]);
  [[[jsMessageMock stub] andReturn:kAmpChannelOpenMessageName] name];
  [(AMPKWebViewerJsMessage *)[[jsMessageMock stub] andReturn:kAmpMessageRequest] type];

  XCTAssertTrue([self.messageHandlerController shouldSendMessage:jsMessageMock]);
}

- (void)testShouldNotSendMessageJSNotReady {
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];
  [self.messageHandlerController setAmpWebViewerController:ampViewer];

  id jsMessageMock = OCMClassMock([AMPKWebViewerJsMessage class]);
  [[[jsMessageMock stub] andReturn:kAmpVisibilityChangeMessageName] name];
  [(AMPKWebViewerJsMessage *)[[jsMessageMock stub] andReturn:kAmpMessageRequest] type];

  XCTAssertFalse([self.messageHandlerController shouldSendMessage:jsMessageMock]);
}

- (void)testHandlingArbitraryRequestMessageWithRSVP {
  AMPKWebViewerBaseMessageHandler *handler = [[AMPKWebViewerBaseMessageHandler alloc] init];
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  id mockWKScriptMessage = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                                 name:@"irrelevant"
                                                            channelID:1
                                                            requestID:2
                                                                 RSVP:YES
                                                                 data:nil
                                                                error:nil];

  XCTAssertThrows([handler handleMessage:mockWKScriptMessage forAmpWebViewerController:ampViewer]);

  XCTAssertEqual(handler.pendingMessages.count, 1);
  XCTAssertEqualObjects([handler.pendingMessages firstObject],
                        [mockWKScriptMessage ampWebViewerJsMessage]);
}

- (void)testHandlingArbitraryRequestMessageWithoutRSVP {
  AMPKWebViewerBaseMessageHandler *handler = [[AMPKWebViewerBaseMessageHandler alloc] init];
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  id mockWKScriptMessage = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                                 name:@"irrelevant"
                                                            channelID:1
                                                            requestID:2
                                                                 RSVP:NO
                                                                 data:nil
                                                                error:nil];

  XCTAssertThrows([handler handleMessage:mockWKScriptMessage forAmpWebViewerController:ampViewer]);

  XCTAssertEqual(handler.pendingMessages.count, 0);
}

- (void)testHandlingArbitraryResponseMessageForRSVP {
  AMPKWebViewerBaseMessageHandler *handler = [[AMPKWebViewerBaseMessageHandler alloc] init];
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  id firstMessage = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                          name:@"irrelevant"
                                                     channelID:1
                                                     requestID:2
                                                          RSVP:YES
                                                          data:nil
                                                         error:nil];

  XCTAssertThrows([handler handleMessage:firstMessage forAmpWebViewerController:ampViewer]);

  id secondMessage = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeResponse
                                                           name:@"irrelevant"
                                                      channelID:1
                                                      requestID:2
                                                           RSVP:NO
                                                           data:nil
                                                          error:nil];

  XCTAssertThrows([handler handleMessage:secondMessage forAmpWebViewerController:ampViewer]);

  XCTAssertEqual(handler.pendingMessages.count, 0);
}

- (void)testHandlingIncorrectRequestArbitraryResponseMessageForRSVP {
  AMPKWebViewerBaseMessageHandler *handler = [[AMPKWebViewerBaseMessageHandler alloc] init];
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  id firstMessage = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                          name:@"irrelevant"
                                                     channelID:1
                                                     requestID:2
                                                          RSVP:YES
                                                          data:nil
                                                         error:nil];

  XCTAssertThrows([handler handleMessage:firstMessage forAmpWebViewerController:ampViewer]);

  id secondMessage = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeResponse
                                                           name:@"irrelevant"
                                                      channelID:1
                                                      requestID:45
                                                           RSVP:NO
                                                           data:nil
                                                          error:nil];

  XCTAssertThrows([handler handleMessage:secondMessage forAmpWebViewerController:ampViewer]);

  XCTAssertEqual(handler.pendingMessages.count, 1);
}

- (void)testHandlingIncorrectChannelArbitraryResponseMessageForRSVP {
  AMPKWebViewerBaseMessageHandler *handler = [[AMPKWebViewerBaseMessageHandler alloc] init];
  AMPKWebViewerViewController *ampViewer = [AMPKTestHelper setupWebViewerViewController];

  id firstMessage = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                          name:@"irrelevant"
                                                     channelID:1
                                                     requestID:2
                                                          RSVP:YES
                                                          data:nil
                                                         error:nil];

  XCTAssertThrows([handler handleMessage:firstMessage forAmpWebViewerController:ampViewer]);

  id secondMessage = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeResponse
                                                           name:@"irrelevant"
                                                      channelID:15
                                                      requestID:2
                                                           RSVP:NO
                                                           data:nil
                                                          error:nil];

  XCTAssertThrows([handler handleMessage:secondMessage forAmpWebViewerController:ampViewer]);

  XCTAssertEqual(handler.pendingMessages.count, 1);
}

@end
