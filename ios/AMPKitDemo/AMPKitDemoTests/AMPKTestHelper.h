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

#import "AMPKWebViewerJsMessage.h"

extern NSString *const kAmpKitTestSourceHostName;

@class AMPKWebViewerViewController;

/** Helper class for creating commonly used obejcts in AmpKit tests. */
@interface AMPKTestHelper : NSObject

/**
 * Creates a class mock for a WKScriptMessage object that can be used to convert to a
 * AMPKWebViewerJsMessage.
 */
+ (id)mockWKScriptMessageForType:(AMPKMessageType)type
                            name:(NSString *)name
                       channelID:(NSInteger)channelID
                       requestID:(NSInteger)requestID
                            RSVP:(BOOL)rsvp
                            data:(id)data
                           error:(NSString *)error;

/** Creates a AMPKWebViewerViewController which has been fully initialized. */
+ (AMPKWebViewerViewController *)setupWebViewerViewController;

/** Creates a class mock for a WKSAMPKWebViewerViewController with the test article URL. */
+ (id)mockViewer;

/** Creates a class mock for a WKSAMPKWebViewerViewController with the specified article URL. */
+ (id)mockViewerWithURL:(NSURL *)url;

@end
