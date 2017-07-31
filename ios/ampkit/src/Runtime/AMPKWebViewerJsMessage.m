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

#import "AMPKWebViewerJsMessage_private.h"

@interface AMPKWebViewerJsMessage ()
@property(nonatomic, copy) NSString *app;
@property(nonatomic) NSInteger channelID;
@property(nonatomic) NSInteger requestID;
@property(nonatomic) BOOL rsvp;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, readwrite) id data;
@property(nonatomic, copy) NSString *type;
@property(nonatomic, copy) NSString *error;
@property(nonatomic) AMPKWebViewerJsMessage *originMessage;
@end

@implementation AMPKWebViewerJsMessage

+ (instancetype)messageWithType:(AMPKMessageType)type
                           name:(NSString *)name
                      channelID:(NSInteger)channelID
                      requestID:(NSInteger)requestID
               responseRequired:(BOOL)rsvp
                           data:(id)data
                  originMessage:(AMPKWebViewerJsMessage *)originMessage
                          error:(NSString *)error {
  AMPKWebViewerJsMessage *message = [[AMPKWebViewerJsMessage alloc] init];
  message.type = [self stringForMessageType:type];
  message.name = name;
  message.channelID = channelID;
  message.requestID = requestID;
  message.rsvp = rsvp;
  message.data = data;
  message.error = error;
  message.originMessage = originMessage;

  return message;
}

+ (NSString *)stringForMessageType:(AMPKMessageType)type {
  return (type == AMPKMessageTypeResponse ? kAmpMessageResponse : kAmpMessageRequest);
}

+ (AMPKMessageType)messageTypeForString:(NSString *)string {
  if ([string isEqualToString:kAmpMessageResponse]) {
    return AMPKMessageTypeResponse;
  } else if ([string isEqualToString:kAmpMessageRequest]) {
    return AMPKMessageTypeRequest;
  } else {
    return AMPKMessageTypeInvalid;
  }
}

- (NSString *)app {
  if (!_app) {
    return @"__AMPHTML__";
  }

  return _app;
}

- (NSString *)jsonString {
  NSError *error;

  NSMutableDictionary *jsonObject = [@{
                                       @"app" : self.app,
                                       @"channelid" : @(self.channelID),
                                       @"requestid" : @(self.requestID),
                                       @"rsvp" : @(self.rsvp),
                                       @"name" : self.name,
                                       @"data" : self.data,
                                       @"type" : self.type,
                                       } mutableCopy];

  if (self.error) {
    jsonObject[@"error"] = self.error;
  }

  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                     options:0
                                                       error:&error];
  NSAssert(error == nil, @"%@, JSON has an unexpected error: %@",
            NSStringFromSelector(_cmd), error);

  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (NSString *)description {
  return [NSString stringWithFormat:@"app: %@, name: %@, type: %@, channelID: %@, requestID: %@, " \
          "rsvp: %@, data: %@%@",
          self.app,
          self.name,
          [self.type isEqualToString:@"s"] ? @"Response" : @"Request",
          @(self.channelID),
          @(self.requestID),
          @(self.rsvp),
          self.data,
          (self.error ? [NSString stringWithFormat:@"error: %@", self.error] : @"")];
}

- (BOOL)isEqual:(id)object {
  if ([object isKindOfClass:[AMPKWebViewerJsMessage class]] && object) {
    AMPKWebViewerJsMessage *other = (AMPKWebViewerJsMessage *)object;
    if ([other.type isEqualToString:self.type] &&
        [other.name isEqualToString:self.name] &&
        other.channelID == self.channelID &&
        other.requestID == self.requestID &&
        other.rsvp == self.rsvp &&
        [self nilSafeA:other.data equalsB:self.data] &&
        [self nilSafeA:other.error equalsB:self.error] &&
        [self nilSafeA:other.originMessage equalsB:self.originMessage]) {
      return YES;
    }
  }

  return NO;
}

- (BOOL)nilSafeA:(id)a equalsB:(id)b {
  return (a == nil && b == nil) || ([a isEqual:b]);
}

@end

@implementation WKScriptMessage (AMP)

- (AMPKWebViewerJsMessage *)ampWebViewerJsMessage {
  if ([[self body] isKindOfClass:[NSDictionary class]]) {
    NSDictionary *jsonData = [self body];
    NSString *app = jsonData[@"app"];
    if ([app isEqualToString:@"__AMPHTML__"]) {
      AMPKMessageType type = [AMPKWebViewerJsMessage messageTypeForString:jsonData[@"type"]];
      if (type != AMPKMessageTypeInvalid) {
        AMPKWebViewerJsMessage *message =
            [AMPKWebViewerJsMessage messageWithType:type
                                               name:jsonData[@"name"]
                                          channelID:[jsonData[@"channelid"] integerValue]
                                          requestID:[jsonData[@"requestid"] integerValue]
                                   responseRequired:[jsonData[@"rsvp"] boolValue]
                                               data:jsonData[@"data"]
                                      originMessage:nil
                                              error:jsonData[@"error"]];
        return message;
      }
    }
  }

  return nil;
}

@end
