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

#import "AMPK.h"

NS_ASSUME_NONNULL_BEGIN

@class AMPKHeaderView;
@protocol AMPKViewControllerDelegate;

/**
 * A concrete implementation of the AMPKViewer with basic functionality that can be used without
 * needing implementation if you do not need a custom header or UI.
 */
@interface AMPKViewController : AMPKViewer

/**
 * When using AMPKViewController, please use the AMPKViewControllerDelegate methods instead.
 */
@property(nonatomic, weak) id<AMPKPresenterProtocol> presenter NS_UNAVAILABLE;

/**
 * When using AMPKViewController, please use the AMPKViewControllerDelegate methods instead.
 */
@property(nonatomic, weak) id<AMPKViewerDelegate> pageViewControllerDelegate NS_UNAVAILABLE;

/**
 * The default AMP header for the AMP Viewer.
 */
@property(nonatomic, readonly) AMPKHeaderView *headerView;

/**
 * The delegate for AMPKViewController which allows customization and provides event information.
 */
@property(nonatomic, weak) id<AMPKViewControllerDelegate> AMPKViewControllerDelegate;

@end

/**
 * The delegate for AMPKViewController which allows customization and provides event information.
 */
@protocol AMPKViewControllerDelegate <NSObject>

/**
 * Called when the AMPViewer should be closed. The client should then dismiss the AMPKViewController
 * in the appropriate mannor.
 * @param sender The source of this close event. Typically this is the @c closeButton from the @c
 * headerView.
 */
- (void)AMPKCloseViewer:(nullable id)sender;

@optional

/**
 * Called when the share dialog has been shown.
 * @param sender The source of this share dialog. Typically this is the @c shareButton from the
 * @c headerView.
 */
- (void)AMPKShareURL:(nullable id)sender;

/**
 * The completion handler to use for the UIActivityViewController on share events.
 */
@property(nonatomic, copy, nullable)
    UIActivityViewControllerCompletionWithItemsHandler shareCompletionWithItemsHandler;

/**
 * Called when an external URL should be presented. AMPKit does not display non-AMP pages in the AMP
 * so another WebView must present this. If you want to display this request in a custom viewer then
 * implement this method and present the given URL. If you do not implement this method Safari View
 * Controller is used to display this page.
 */
- (void)AMPKPresentExternalURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
