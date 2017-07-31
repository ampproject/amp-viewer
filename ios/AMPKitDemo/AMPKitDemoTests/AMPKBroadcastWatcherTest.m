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

#import "AMPKBroadcastWatcher.h"

#import <XCTest/XCTest.h>

#import "AMPKBroadcastWatcher_private.h"
#import "AMPKWebViewerJsMessage.h"
#import "AMPKWebViewerMessageHandlerController.h"
#import "AMPKWebViewerMessageHandlerController_private.h"
#import "AMPKTestHelper.h"

#import <OCMock/OCMock.h>

static NSString *const kAmpMessageTestData = @"data";

@interface AMPKBroadcastWatcherTest : XCTestCase
@property(nonatomic) AMPKBroadcastWatcher *watcher;
@property(nonatomic) AMPKWebViewerMessageHandlerController *controller;
@property(nonatomic) AMPKWebViewerJsMessage *originMessage;
@property(nonatomic) id mockAmpViewer;
@end

@implementation AMPKBroadcastWatcherTest

- (void)setUp {
  self.mockAmpViewer = [AMPKTestHelper mockViewer];
  self.controller = [[AMPKWebViewerMessageHandlerController alloc] init];
  self.controller.ampWebViewerController = self.mockAmpViewer;
  self.originMessage = [self messageWithRSVP:YES];
  self.watcher = [[AMPKBroadcastWatcher alloc] initWithOriginBroadcast:self.originMessage
                                                forDestinationController:self.controller];
  [super setUp];
}

- (void)tearDown {
  self.controller = nil;
  self.originMessage = nil;
  self.watcher = nil;
  [super tearDown];
}

- (void)testForwardingRSVPMessage {
  AMPKWebViewerMessageHandlerController *forwardController =
      [[AMPKWebViewerMessageHandlerController alloc] init];
  forwardController.ampWebViewerController = self.mockAmpViewer;
  id forwardMock = OCMPartialMock(forwardController);
  [[forwardMock expect] forwardBroadcast:self.originMessage];

  [self.watcher forwardMessageToController:forwardMock];

  XCTAssertTrue(self.watcher.pending);
  XCTAssertFalse(self.watcher.completed);
  XCTAssertEqual(self.watcher.forwardedControllers.count, 1);
}

- (void)testForwardingNonRSVPMessage {
  self.watcher.origin = [self messageWithRSVP:NO];

  AMPKWebViewerMessageHandlerController *forwardController =
      [[AMPKWebViewerMessageHandlerController alloc] init];
  forwardController.ampWebViewerController = self.mockAmpViewer;

  [self.watcher forwardMessageToController:forwardController];

  XCTAssertFalse(self.watcher.pending);
  XCTAssertEqual(self.watcher.forwardedControllers.count, 0);
}

- (void)testRespondToSourceWithReplies {
  AMPKWebViewerMessageHandlerController *forwardController =
      [[AMPKWebViewerMessageHandlerController alloc] init];
  forwardController.ampWebViewerController = self.mockAmpViewer;

  [self.watcher forwardMessageToController:forwardController];

  id mockController = OCMStrictClassMock([AMPKWebViewerMessageHandlerController class]);
  id argument = [OCMArg checkWithBlock:^BOOL(id obj) {
    if ([obj isKindOfClass:[AMPKWebViewerJsMessage class]]) {
      AMPKWebViewerJsMessage *message = (AMPKWebViewerJsMessage *)obj;
      if (message.originMessage == self.originMessage &&
          message.channelID == self.originMessage.channelID &&
          message.requestID == self.originMessage.requestID &&
          [message.data isEqual:@[kAmpMessageTestData]] &&
          !message.rsvp) {
        return YES;
      }
    }
    return NO;
  }];
  [[mockController expect] sendAmpJsMessage:argument];

  self.watcher.controller = mockController;
  AMPKWebViewerJsMessage *reply = [self messageWithRSVP:NO];
  [self.watcher receiveMessage:reply fromController:forwardController];

  XCTAssertFalse(self.watcher.pending);
  XCTAssertTrue(self.watcher.completed);
  [mockController verify];
}

- (void)testRespondToSourceNoReplies {
  id mockController = OCMStrictClassMock([AMPKWebViewerMessageHandlerController class]);
  id argument = [OCMArg checkWithBlock:^BOOL(id obj) {
    if ([obj isKindOfClass:[AMPKWebViewerJsMessage class]]) {
      AMPKWebViewerJsMessage *message = (AMPKWebViewerJsMessage *)obj;
      if (message.originMessage == self.originMessage &&
          message.channelID == self.originMessage.channelID &&
          message.requestID == self.originMessage.requestID &&
          !message.rsvp) {
        return YES;
      }
    }
    return NO;
  }];
  [[mockController expect] sendAmpJsMessage:argument];

  self.watcher.controller = mockController;

  [self.watcher respondToSourceController];

  XCTAssertFalse(self.watcher.pending);
  XCTAssertTrue(self.watcher.completed);
  [mockController verify];
}

- (void)testForwardingNilMessageToWatcherFails {
  XCTAssertThrows([self.watcher receiveMessage:nil fromController:self.controller]);
}

- (void)testCancelMessageFromController {
  AMPKWebViewerMessageHandlerController *forwardController =
  [[AMPKWebViewerMessageHandlerController alloc] init];
      forwardController.ampWebViewerController = self.mockAmpViewer;

  [self.watcher forwardMessageToController:forwardController];
  [self.watcher cancelMessageFromController:forwardController];

  XCTAssertEqual(self.watcher.forwardedControllers.count, 0);
}

- (void)testReceivingMessageFromController {
  AMPKWebViewerMessageHandlerController *forwardController =
  [[AMPKWebViewerMessageHandlerController alloc] init];
      forwardController.ampWebViewerController = self.mockAmpViewer;

  [self.watcher forwardMessageToController:forwardController];

  AMPKWebViewerJsMessage *reply = [self messageWithRSVP:NO];

  [self.watcher receiveMessage:reply fromController:forwardController];

  XCTAssertEqual(self.watcher.replies.count, 1);

}

- (AMPKWebViewerJsMessage *)messageWithRSVP:(BOOL)RSVP {
  return [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                            name:kAmpBroadcastMessageName
                                       channelID:0
                                       requestID:1
                                responseRequired:RSVP
                                            data:kAmpMessageTestData
                                   originMessage:nil
                                           error:nil];
}



@end
