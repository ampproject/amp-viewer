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

@class AMPKWebViewerJsMessage;
@class AMPKWebViewerMessageHandlerController;
@class AMPKWebViewerViewController;

/**
 * A class which manages routing of an incoming broadcast message from a MessageHandler. If needed
 * a watcher will be retained to track the status of replies from the original incoming broadcast.
 */
@interface AMPKMessageBroadcaster : NSObject

/**
 * Call this method to inform the MessageBroadcast that the set of AMP view controllers that it
 * should be routing broadcast mesaages between has changed. This could cause a current watcher to
 * be cancelled or to be completed depending on if it was waiting for a reponse or not.
 */
- (void)setLoadedControllers:(NSSet <AMPKWebViewerMessageHandlerController *> *)loadedControllers;

/**
 * This method will determine where to route an incoming broadcast message such as an existing or
 * new watcher. Call this method directly from the broadcast message handler which recieved the
 * message.
 */
- (void)postBroadcast:(AMPKWebViewerJsMessage *)broadcast
       fromController:(AMPKWebViewerMessageHandlerController *)controller;

/**
 * When an AMP view controller is being recycled or otherwise moved out of memory (it is no longer
 * pre-loaded), all pending broadcast messages associated with that AMP view must be cancelled. Call
 * this method directly from the broadcast message hander associated with the AMP view controller
 * that is no longer pre-loaded.
 */
- (void)cancelBroadcast:(AMPKWebViewerJsMessage *)broadcast
          forController:(AMPKWebViewerMessageHandlerController *)controller;

@end
