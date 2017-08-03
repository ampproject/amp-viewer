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

#import "AMPKBroadcastWatcher_private.h"
#import "AMPKWebViewerJsMessage.h"
#import "AMPKWebViewerMessageHandlerController.h"
#import "AMPKWebViewerViewController.h"

@implementation AMPKBroadcastWatcher

- (instancetype)initWithOriginBroadcast:(__weak AMPKWebViewerJsMessage *)origin
               forDestinationController:
    (__weak AMPKWebViewerMessageHandlerController *)controller {
  self = [super init];
  if (self) {
    _controller = controller;
    _origin = origin;
    _forwardedControllers = [NSHashTable hashTableWithOptions:NSHashTableWeakMemory];
    _replies = [[NSMutableArray alloc] init];
    _pending = NO;
  }
  return self;
}

- (void)forwardMessageToController:(AMPKWebViewerMessageHandlerController *)controller {
  NSString *fromHost = [_controller.ampWebViewerController.article.publisherURL host];
  NSString *toHost = [controller.ampWebViewerController.article.publisherURL host];
  if (controller != _controller && [toHost isEqualToString:fromHost]) {
    [controller forwardBroadcast:_origin];

    if (_origin.rsvp) {
      _pending = YES;
      _completed = NO;
      [_forwardedControllers addObject:controller];
    }
  }
}

- (void)receiveMessage:(AMPKWebViewerJsMessage *)response
        fromController:(AMPKWebViewerMessageHandlerController *)controller {
  NSAssert(response, @"You must provide a response when forwarding a message to the watcher");
  [_replies addObject:response];
  [self cancelMessageFromController:controller];
}

- (void)cancelMessageFromController:(AMPKWebViewerMessageHandlerController *)controller {
  [_forwardedControllers removeObject:controller];

  if ([_forwardedControllers count] == 0) {
    [self respondToSourceController];
  }
}

- (void)cancel {
  [self respondToSourceController];
}

- (void)respondToSourceController {
  NSString *error = nil;
  NSMutableArray *responses = [[NSMutableArray alloc] initWithCapacity:_replies.count];

  // If there are still pending webviews which have been forwarded the origin message, then the
  // origin itself has been cancelled for some reason, and we should reply with an error instead of
  // any data.
  if (_forwardedControllers.count != 0) {
    error = @"View unloaded";
  } else {
    for (AMPKWebViewerJsMessage *reply in _replies) {
      if ([reply error]) {
        [responses addObject:[reply error]];
      } else {
        [responses addObject: [reply data] != nil ? [reply data] : [NSNull null]];
      }
    }
  }

  AMPKWebViewerJsMessage *replyMessage =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeResponse
                                         name:@"broadcast"
                                    channelID:_origin.channelID
                                    requestID:_origin.requestID
                             responseRequired:NO
                                         data:responses
                                originMessage:_origin
                                        error:error];

  [_controller sendAmpJsMessage:replyMessage];
  _completed = YES;
  _pending = NO;
}

@end
