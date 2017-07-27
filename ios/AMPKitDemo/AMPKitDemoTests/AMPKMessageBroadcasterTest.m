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

#import "AMPKMessageBroadcaster.h"

#import <XCTest/XCTest.h>

#import "AMPKBroadcastWatcher.h"
#import "AMPKMessageBroadcaster_private.h"
#import "AMPKWebViewerJsMessage.h"
#import "AMPKWebViewerMessageHandlerController.h"
#import "AMPKWebViewerMessageHandlerController_private.h"
#import "AMPKTestHelper.h"
#import "AMPKWebViewerViewController.h"

#import <OCMock/OCMock.h>

static NSString *const kTestBroadcastDataString = @"broadcast";
static NSString *const kTestBroadcastMessageURLString = @"http://www.nope.com";

@interface AMPKMessageBroadcasterTest : XCTestCase
@property(nonatomic) AMPKMessageBroadcaster *broadcaster;
@end

@implementation AMPKMessageBroadcasterTest

- (void)setUp {
  [super setUp];
  self.broadcaster = [[AMPKMessageBroadcaster alloc] init];
}

- (void)tearDown {
  self.broadcaster = nil;
  [super tearDown];
}

- (void)testSettingHandlers {
  NSUInteger count = 3;
  [self.broadcaster setLoadedControllers:[[self createSetOfHandlersWithCount:count] copy]];

  XCTAssertEqual(count, self.broadcaster.messageHandlers.count);
}

- (void)testSettingPreviouslySetHandlers {
  NSUInteger count = 3;
  [self.broadcaster setLoadedControllers:[[self createSetOfHandlersWithCount:count] copy]];

  NSSet *newHandlers = [self createSetOfHandlersWithCount:3];
  [self.broadcaster setLoadedControllers:newHandlers];

  XCTAssertEqualObjects(newHandlers, self.broadcaster.messageHandlers);
}

- (void)testAddingNewHandlers {
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:3 strickMock:YES];
  [self.broadcaster setLoadedControllers:handlers];

  [handlers addObject:[self strickMockForHandler]];

  [self.broadcaster setLoadedControllers:handlers];
}

- (void)testReplacingHandlers {
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:3 strickMock:YES];
  for (id mock in handlers) {
    [[mock expect] cancelPendingMessages];
  }
  [self.broadcaster setLoadedControllers:handlers];
  [handlers removeAllObjects];
  [handlers addObject:[self strickMockForHandler]];

  [self.broadcaster setLoadedControllers:handlers];
  for (id mock in handlers) {
    [mock verify];
  }
}

- (void)testForwardingRequest {
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:3];
  [self.broadcaster setLoadedControllers:handlers];
  AMPKWebViewerMessageHandlerController *fromController = [handlers anyObject];
  id viewerMock = [AMPKTestHelper mockViewer];

  for (AMPKWebViewerMessageHandlerController *handler in handlers) {
    handler.ampWebViewerController = viewerMock;
  }

  AMPKWebViewerJsMessage *broadcast =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:YES
                                         data:kTestBroadcastDataString
                                originMessage:nil
                                        error:nil];

  [self.broadcaster postBroadcast:broadcast fromController:fromController];

  XCTAssertEqual(self.broadcaster.pendingBroadcast.count, 1);
}

- (void)testForwardingRequestOfOnlyOneController {
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:1];
  [self.broadcaster setLoadedControllers:handlers];
  AMPKWebViewerMessageHandlerController *fromController = [handlers anyObject];
  id viewerMock = [AMPKTestHelper mockViewer];

  for (AMPKWebViewerMessageHandlerController *handler in handlers) {
    handler.ampWebViewerController = viewerMock;
  }

  AMPKWebViewerJsMessage *broadcast =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:YES
                                         data:kTestBroadcastDataString
                                originMessage:nil
                                        error:nil];

  [self.broadcaster postBroadcast:broadcast fromController:fromController];

  XCTAssertEqual(self.broadcaster.pendingBroadcast.count, 0);
}

- (void)testForwardingRequestWithNoReply {
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:3];
  [self.broadcaster setLoadedControllers:handlers];
  AMPKWebViewerMessageHandlerController *fromController = [handlers anyObject];
  id viewerMock = [AMPKTestHelper mockViewer];

  for (AMPKWebViewerMessageHandlerController *handler in handlers) {
    handler.ampWebViewerController = viewerMock;
  }

  AMPKWebViewerJsMessage *broadcast =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:NO
                                         data:kTestBroadcastDataString
                                originMessage:nil
                                        error:nil];

  [self.broadcaster postBroadcast:broadcast fromController:fromController];

  XCTAssertEqual(self.broadcaster.pendingBroadcast.count, 0);
}

- (void)testForwardingMultipleRequests {
  NSUInteger numberOfHandlers = 3;
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:numberOfHandlers];
  [self.broadcaster setLoadedControllers:handlers];
  AMPKWebViewerMessageHandlerController *fromController = [handlers anyObject];
  id viewerMock = [AMPKTestHelper mockViewer];

  for (AMPKWebViewerMessageHandlerController *handler in handlers) {
    handler.ampWebViewerController = viewerMock;
  }

  NSUInteger numberOfBroadcastMessages = 3;

  for (NSUInteger i = 0; i < numberOfBroadcastMessages; i++) {
    AMPKWebViewerJsMessage *broadcast =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpBroadcastMessageName
                                    channelID:0 + i
                                    requestID:5 + i
                             responseRequired:YES
                                         data:kTestBroadcastDataString
                                originMessage:nil
                                        error:nil];

    [self.broadcaster postBroadcast:broadcast fromController:fromController];
  }

  XCTAssertEqual(self.broadcaster.pendingBroadcast.count, numberOfBroadcastMessages);
}

- (void)testResponseToOriginSingleBroadcast {
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:2];
  [self.broadcaster setLoadedControllers:handlers];
  AMPKWebViewerMessageHandlerController *fromController = [handlers anyObject];
  id viewerMock = [AMPKTestHelper mockViewer];

  for (AMPKWebViewerMessageHandlerController *handler in handlers) {
    handler.ampWebViewerController = viewerMock;
  }

  AMPKWebViewerJsMessage *broadcast =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:YES
                                         data:kTestBroadcastDataString
                                originMessage:nil
                                        error:nil];

  [self.broadcaster postBroadcast:broadcast fromController:fromController];

  NSMutableSet *fromSet = [handlers mutableCopyWithZone:nil];
  [fromSet removeObject:fromController];

  AMPKWebViewerMessageHandlerController *fromReply = [fromSet anyObject];

  AMPKWebViewerJsMessage *reply =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeResponse
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:YES
                                         data:kTestBroadcastDataString
                                originMessage:broadcast
                                        error:nil];

  [self.broadcaster postBroadcast:reply fromController:fromReply];

  XCTAssertEqual(self.broadcaster.pendingBroadcast.count, 0);
}

- (void)testResponseToOriginMultipleBroadcastFailsWithOneReply {
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:3];
  [self.broadcaster setLoadedControllers:handlers];
  AMPKWebViewerMessageHandlerController *fromController = [handlers anyObject];
  id viewerMock = [AMPKTestHelper mockViewer];

  for (AMPKWebViewerMessageHandlerController *handler in handlers) {
    handler.ampWebViewerController = viewerMock;
  }

  AMPKWebViewerJsMessage *broadcast =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:YES
                                         data:kTestBroadcastDataString
                                originMessage:nil
                                        error:nil];

  [self.broadcaster postBroadcast:broadcast fromController:fromController];

  AMPKBroadcastWatcher *watcher = [self.broadcaster.pendingBroadcast objectForKey:broadcast];
  id mockWatcher = OCMPartialMock(watcher);
  [[mockWatcher expect] completed];

  NSMutableSet *fromSet = [handlers mutableCopyWithZone:nil];
  [fromSet removeObject:fromController];

  AMPKWebViewerMessageHandlerController *fromReply = [fromSet anyObject];

  AMPKWebViewerJsMessage *reply =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeResponse
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:YES
                                         data:kTestBroadcastDataString
                                originMessage:broadcast
                                        error:nil];

  [self.broadcaster postBroadcast:reply fromController:fromReply];

  [mockWatcher verify];

  XCTAssertNotEqual(self.broadcaster.pendingBroadcast.count, 0);
}

- (void)testResponseToOriginMultipleBroadcast {
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:3];
  [self.broadcaster setLoadedControllers:handlers];
  AMPKWebViewerMessageHandlerController *fromController = [handlers anyObject];
  id viewerMock = [AMPKTestHelper mockViewer];

  for (AMPKWebViewerMessageHandlerController *handler in handlers) {
    handler.ampWebViewerController = viewerMock;
  }

  AMPKWebViewerJsMessage *broadcast =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:YES
                                         data:kTestBroadcastDataString
                                originMessage:nil
                                        error:nil];

  [self.broadcaster postBroadcast:broadcast fromController:fromController];

  NSMutableSet *fromSet = [handlers mutableCopyWithZone:nil];
  [fromSet removeObject:fromController];

  AMPKWebViewerJsMessage *reply =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeResponse
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:NO
                                         data:kTestBroadcastDataString
                                originMessage:broadcast
                                        error:nil];

  for (AMPKWebViewerMessageHandlerController *fromReply in fromSet) {
    [self.broadcaster postBroadcast:reply fromController:fromReply];
  }

  XCTAssertEqual(self.broadcaster.pendingBroadcast.count, 0);
}

- (void)testCancelOriginBroadcast {
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:2];
  [self.broadcaster setLoadedControllers:handlers];
  AMPKWebViewerMessageHandlerController *fromController = [handlers anyObject];
  id viewerMock = [AMPKTestHelper mockViewer];

  for (AMPKWebViewerMessageHandlerController *handler in handlers) {
    handler.ampWebViewerController = viewerMock;
  }

  AMPKWebViewerJsMessage *broadcast =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:YES
                                         data:kTestBroadcastDataString
                                originMessage:nil
                                        error:nil];

  [self.broadcaster postBroadcast:broadcast fromController:fromController];

  AMPKBroadcastWatcher *watcher = [self.broadcaster.pendingBroadcast objectForKey:broadcast];
  id mockWatcher = OCMPartialMock(watcher);
  [[mockWatcher expect] cancel];

  [self.broadcaster cancelBroadcast:broadcast forController:fromController];

  [mockWatcher verify];

  XCTAssertEqual(self.broadcaster.pendingBroadcast.count, 0);
}


- (void)testCancelResponseToOriginBroadcast {
  NSMutableSet *handlers = [self createSetOfHandlersWithCount:2];
  [self.broadcaster setLoadedControllers:handlers];
  AMPKWebViewerMessageHandlerController *fromController = [handlers anyObject];
  id viewerMock = [AMPKTestHelper mockViewer];

  for (AMPKWebViewerMessageHandlerController *handler in handlers) {
    handler.ampWebViewerController = viewerMock;
  }

  AMPKWebViewerJsMessage *broadcast =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:YES
                                         data:kTestBroadcastDataString
                                originMessage:nil
                                        error:nil];

  [self.broadcaster postBroadcast:broadcast fromController:fromController];

  AMPKWebViewerJsMessage *reply =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeResponse
                                         name:kAmpBroadcastMessageName
                                    channelID:0
                                    requestID:5
                             responseRequired:NO
                                         data:kTestBroadcastDataString
                                originMessage:broadcast
                                        error:nil];

  NSMutableSet *fromSet = [handlers mutableCopyWithZone:nil];
  [fromSet removeObject:fromController];
  AMPKWebViewerMessageHandlerController *fromReply = [fromSet anyObject];

  AMPKBroadcastWatcher *watcher = [self.broadcaster.pendingBroadcast objectForKey:broadcast];
  id mockWatcher = OCMPartialMock(watcher);

  [[mockWatcher expect] cancelMessageFromController:fromReply];

  [self.broadcaster cancelBroadcast:reply forController:fromReply];

  [mockWatcher verify];
}

- (NSMutableSet *)createSetOfHandlersWithCount:(NSInteger)count {
  return [self createSetOfHandlersWithCount:count strickMock:NO];
}

- (NSMutableSet *)createSetOfHandlersWithCount:(NSInteger)count strickMock:(BOOL)strickMock {
  NSMutableSet *set = [NSMutableSet setWithCapacity:count];
  for (NSUInteger i = 0; i < count; i++) {
    AMPKWebViewerMessageHandlerController *handler;
    if (strickMock) {
      handler = [self strickMockForHandler];
    } else {
      handler = [[AMPKWebViewerMessageHandlerController alloc] init];
      handler.sourceHostName = kAmpKitTestSourceHostName;
    }

    [set addObject:handler];
  }

  return set;
}

- (id)strickMockForHandler {
  id mock = OCMStrictClassMock([AMPKWebViewerMessageHandlerController class]);
  [[mock stub] setAmpMessageBroadcaster:OCMOCK_ANY];

  return mock;
}

- (NSURL *)testURL {
  return [NSURL URLWithString:kTestBroadcastMessageURLString];
}

@end
