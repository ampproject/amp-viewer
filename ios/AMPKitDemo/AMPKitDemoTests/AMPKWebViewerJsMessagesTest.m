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

#import <XCTest/XCTest.h>

#import "AMPKTestHelper.h"

@interface AMPKWebViewerJsMessagesTest : XCTestCase

@end

@implementation AMPKWebViewerJsMessagesTest

- (void)testConvertScriptToMessage {
  id mockScript = [AMPKTestHelper mockWKScriptMessageForType:AMPKMessageTypeRequest
                                                        name:@"name"
                                                   channelID:0
                                                   requestID:1
                                                        RSVP:NO
                                                        data:@"data"
                                                       error:nil];

  AMPKWebViewerJsMessage *message =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"name"
                                    channelID:0
                                    requestID:1
                             responseRequired:NO
                                         data:@"data"
                                originMessage:nil
                                        error:nil];

  XCTAssertEqualObjects(message, [mockScript ampWebViewerJsMessage]);
}

- (void)testEqualsNormalFields {
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  XCTAssertEqualObjects(message1, message2);
}

- (void)testEqualsAllFields {
  AMPKWebViewerJsMessage *originMessage =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"parent"
                                    channelID:2
                                    requestID:1
                             responseRequired:NO
                                         data:nil
                                originMessage:nil
                                        error:@"origin error"];
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                            responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:originMessage
                                        error:@"error"];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:originMessage
                                        error:@"error"];


  XCTAssertEqualObjects(message1, message2);
}

- (void)testEqualsMismatchTypes {
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeResponse
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  XCTAssertNotEqualObjects(message1, message2);
}

- (void)testEqualsMismatchNames {
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test 1"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  XCTAssertNotEqualObjects(message1, message2);
}

- (void)testEqualsMismatchChannelId {
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:1
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  XCTAssertNotEqualObjects(message1, message2);
}

- (void)testEqualsMismatchRequestId {
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:1
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  XCTAssertNotEqualObjects(message1, message2);
}

- (void)testEqualsMismatchRSVP {
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:NO
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  XCTAssertNotEqualObjects(message1, message2);
}

- (void)testEqualsMismatchData {
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:nil
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  XCTAssertNotEqualObjects(message1, message2);
}

- (void)testEqualsMismatchDataContents {
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test1" : @"test1"}
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  XCTAssertNotEqualObjects(message1, message2);
}

- (void)testEqualsMismatchDataTypes {
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test1" : @"test1"}
                                originMessage:nil
                                        error:nil];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@(YES)
                                originMessage:nil
                                        error:nil];

  XCTAssertNotEqualObjects(message1, message2);
}

- (void)testEqualsMismatchOrigin {
    AMPKWebViewerJsMessage *originMessage =
        [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                          name:@"parent"
                                     channelID:2
                                     requestID:1
                              responseRequired:NO
                                          data:nil
                                 originMessage:nil
                                         error:@"origin error"];

  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:originMessage
                                        error:nil];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  XCTAssertNotEqualObjects(message1, message2);
}

- (void)testEqualsMismatchError {
  AMPKWebViewerJsMessage *message1 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:@"error"];

  AMPKWebViewerJsMessage *message2 =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeRequest
                                         name:@"test"
                                    channelID:0
                                    requestID:0
                             responseRequired:YES
                                         data:@{@"test" : @"test"}
                                originMessage:nil
                                        error:nil];

  XCTAssertNotEqualObjects(message1, message2);
}
@end
