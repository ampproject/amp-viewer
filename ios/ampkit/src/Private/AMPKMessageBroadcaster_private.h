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

@class AMPKBroadcastWatcher;
@class AMPKWebViewerJsMessage;

/** Provide interface access for Unit Test. */
@interface AMPKMessageBroadcaster()

@property(nonatomic) NSMutableSet <AMPKWebViewerMessageHandlerController *> *messageHandlers;
// Stores the relationship between a forwarded message and the watcher which is watching the
// status of the forwards.
@property(nonatomic)
    NSMapTable <AMPKWebViewerJsMessage *, AMPKBroadcastWatcher *> *pendingBroadcast;

@end
