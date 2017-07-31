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
#import <WebKit/WebKit.h>

typedef void (^AMPKWebViewerJsResponse)(NSString *, NSError *);

/** Defines the two types of AMPMessages that we can send/receive from the document. */
typedef NS_ENUM(NSInteger, AMPKMessageType) {
  AMPKMessageTypeRequest = 0,
  AMPKMessageTypeResponse = 1,
  AMPKMessageTypeInvalid = -1
};

/**
 * Message class for the AMP JS.
 * TODO (stephen-deg): Add link to message format documentation.
 */

@interface AMPKWebViewerJsMessage : NSObject

@property(nonatomic, copy, readonly) NSString *app;
@property(nonatomic, readonly) NSInteger channelID;
@property(nonatomic, readonly) NSInteger requestID;
@property(nonatomic, readonly) BOOL rsvp;
@property(nonatomic, copy, readonly) NSString *name;
@property(nonatomic, readonly) id data;
@property(nonatomic, copy, readonly) NSString *type;
@property(nonatomic, copy, readonly) NSString *error;
@property(nonatomic, readonly) AMPKWebViewerJsMessage *originMessage;

@property(nonatomic, copy) AMPKWebViewerJsResponse jsResponse;

+ (instancetype)messageWithType:(AMPKMessageType)type
                           name:(NSString *)name
                      channelID:(NSInteger)channelID
                      requestID:(NSInteger)requestID
               responseRequired:(BOOL)rsvp
                           data:(id)data
                  originMessage:(AMPKWebViewerJsMessage *)originMessage
                          error:(NSString *)error;

+ (AMPKMessageType)messageTypeForString:(NSString *)string;

/** Converts the message into the appropriate JSON string. */
- (NSString *)jsonString;

@end

@interface WKScriptMessage (AMP)

/** Converts the message received into the appropriate object if it is of the correct type. */
- (AMPKWebViewerJsMessage *)ampWebViewerJsMessage;

@end
