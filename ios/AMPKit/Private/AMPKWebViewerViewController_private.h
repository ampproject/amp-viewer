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

#import "AMPKWebViewerViewController.h"

/** Provide interface access for AMPKViewerDataSource. */
@interface AMPKWebViewerViewController ()

@property(nonatomic, assign) CGPoint viewerContentOffset;
@property(nonatomic, assign) NSInteger viewerDataSourceIndex;

- (void)prepareForReuse;

@end

/** Private interface for AMP Runtime to interact with AmpWebViewer. */
@interface AMPKWebViewerViewController ()

/** This should be called when the document sends the openChannel message. */
- (void)channelOpenWithMessage:(AMPKWebViewerJsMessage *)message;

/**
 * This will be called when the AMP runtime informs the webview that the document has loaded
 * successfully. Prior to this call, you should not consider the amp document "ready".
 */
- (void)AMPDocumentLoadedWithMessage:(AMPKWebViewerJsMessage *)message;

/** This will be called when the AMP runtime requests that the viewer enter full overlay mode. */
- (void)requestFullOverlayMode;

/** This will be called when the AMP runtime requests that the viewer exit full overlay mode. */
- (void)cancelFullOverlayMode;

@end

/** Provide interface access for AMPKWebViewerMessageHandlerController. */
@class AMPKWebViewerJsMessage;
@interface AMPKWebViewerViewController ()

@property(nonatomic, assign) BOOL ampJsReady;

/** This should be called when the document sends the openChannel message. */
- (void)channelOpenWithMessage:(AMPKWebViewerJsMessage *)message;

@end

/** Provide interface access for Unit Test. */
@interface AMPKWebViewerViewController ()

@property(nonatomic, assign, readonly) CGPoint initialContentOffset;

@end
