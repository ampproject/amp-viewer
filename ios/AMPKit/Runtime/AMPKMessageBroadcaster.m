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

#import "AMPKBroadcastWatcher.h"
#import "AMPKMessageBroadcaster_private.h"
#import "AMPKWebViewerJsMessage.h"
#import "AMPKWebViewerMessageHandlerController.h"
#import "AMPKWebViewerViewController.h"

@implementation AMPKMessageBroadcaster

- (instancetype)init {
  self = [super init];
  if (self) {
    _messageHandlers = [[NSMutableSet alloc] initWithCapacity:3];
    const NSPointerFunctionsOptions keyOptions =
        NSMapTableObjectPointerPersonality | NSMapTableStrongMemory;
    _pendingBroadcast = [NSMapTable mapTableWithKeyOptions:keyOptions
                                              valueOptions:NSMapTableStrongMemory];
  }
  return self;
}

- (void)setLoadedControllers:
    (NSSet <AMPKWebViewerMessageHandlerController *> *)loadedControllers {
  for (AMPKWebViewerMessageHandlerController *controller in loadedControllers) {
    [controller setAmpMessageBroadcaster:self];
  }

  [_messageHandlers minusSet:loadedControllers];

  [_messageHandlers enumerateObjectsUsingBlock:
       ^(AMPKWebViewerMessageHandlerController * _Nonnull obj, BOOL * _Nonnull stop) {
         [obj cancelPendingMessages];
       }];

  [_messageHandlers setSet:loadedControllers];
}

- (void)postBroadcast:(AMPKWebViewerJsMessage *)broadcast
       fromController:(AMPKWebViewerMessageHandlerController *)controller {

  // When a message is received, it is either a request or a response. Requests should be forwarded
  // on using a watcher.
  AMPKMessageType type = [AMPKWebViewerJsMessage messageTypeForString:[broadcast type]];
  NSAssert(type != AMPKMessageTypeInvalid, @"Message type should not be invalid type");
  switch (type) {
    case AMPKMessageTypeRequest: {
      AMPKBroadcastWatcher *watcher =
          [[AMPKBroadcastWatcher alloc] initWithOriginBroadcast:broadcast
                                         forDestinationController:controller];
      for (AMPKWebViewerMessageHandlerController *controller in _messageHandlers) {
        [watcher forwardMessageToController:controller];
      }

      // If the watcher has any pending messages then store the watcher and associated it with the
      // origin message.
      if ([watcher pending]) {
        [_pendingBroadcast setObject:watcher forKey:broadcast];
      }
      break;
    }
    case AMPKMessageTypeResponse: {
      // If this is a reponse, then find the watcher associated with the origin and remove inform it
      // of the reponse.
      AMPKWebViewerJsMessage *originMessage = [broadcast originMessage];
      AMPKBroadcastWatcher *watcher = [_pendingBroadcast objectForKey:originMessage];
      [watcher receiveMessage:broadcast fromController:controller];
      // If this watcher is complete following the reception of this message, then the watcher is no
      // longer needed.
      if ([watcher completed]) {
        [_pendingBroadcast removeObjectForKey:originMessage];
      }
      break;
    }
    case AMPKMessageTypeInvalid:
      break;
  }
}

- (void)cancelBroadcast:(AMPKWebViewerJsMessage *)broadcast
          forController:(AMPKWebViewerMessageHandlerController *)controller {
  AMPKBroadcastWatcher *watcher = [_pendingBroadcast objectForKey:broadcast];

  // Whenever a cancellation is received, the message can be one of two types: either an origin
  // message which is watching for other messages and therefore the watcher should be cancelled or
  // it is a reply to an origin message and the webview which sent the cancellation should no longer
  // be tracked by the respective origin's watcher.
  if (watcher) {
    [watcher cancel];
    [_pendingBroadcast removeObjectForKey:broadcast];
  } else {
    watcher = [_pendingBroadcast objectForKey:broadcast.originMessage];
    [watcher cancelMessageFromController:controller];
  }
}

@end
