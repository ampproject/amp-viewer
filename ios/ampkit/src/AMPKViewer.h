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
#import <UIKit/UIKit.h>

#import "AMPKDefines.h"

@class AMPKWebViewerViewController;
@class AMPKViewerDataSource;
@protocol AMPKViewerDelegate;
@protocol AMPKPresenterProtocol;

/**
 * A viewController that renders the AMP article list. It will show
 * articles as horizontial paging style.
 */
@interface AMPKViewer : UIPageViewController <UIPageViewControllerDelegate>

@property(nonatomic, weak) id<AMPKViewerDelegate> pageViewControllerDelegate;
/**
 * The viewerDataSource that implements UIPageViewControllerDataSource and
 * provides a set of AMP viewers for rendering.
 */
@property(nonatomic, readonly) AMPKViewerDataSource *viewerDataSource;

/**
 * Return the currently onscreen ampWebViewerController.
 */
@property(nonatomic, readonly) AMPKWebViewerViewController *currentAmpWebViewerController;

/**
 * Support customized presentation for a certain event.
 */
@property(nonatomic, weak) id<AMPKPresenterProtocol> presenter;

/**
 * Refers to current visible AMP article's index.
 */
@property(nonatomic, readonly) NSInteger currentViewerIndex;


- (instancetype)initWithViewerDataSource:(AMPKViewerDataSource *)viewerDataSource
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)coder NS_UNAVAILABLE;
- (instancetype)
    initWithTransitionStyle:(UIPageViewControllerTransitionStyle)style
      navigationOrientation:(UIPageViewControllerNavigationOrientation)navigationOrientation
                    options:(NSDictionary<NSString *, id> *)options NS_UNAVAILABLE;

/** Shows a particular AMP article via subscripting style. */
- (void)setCurrentViewerIndex:(NSInteger)visibleViewerIndex;

@end

/** Class extension for subclassing implementation. */
@interface AMPKViewer ()

- (void)pageViewController:(UIPageViewController *)pageViewController
    willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers
    NS_REQUIRES_SUPER;

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
       transitionCompleted:(BOOL)completed NS_REQUIRES_SUPER;

@end

/** Class extension for AMP runtime endpoints. These methods are suitable for subclassing. */
@interface AMPKViewer()

/**
 * Called by AMP runtime during full overlay mode to prevent/reenable scrolling depending on the
 * full overlay state.
 */
- (void)setPagingEnabled:(BOOL)enabled;

/**
 * Called by AMP runtime during full overlay mode to hide/show any header depending on the full
 * overlay state. By default, there is no implementation.
 */
- (void)setHeaderVisible:(BOOL)visible;

@end

@protocol AMPKViewerDelegate <NSObject>

/**
 * Notifies the delegate that currentAmpWebViewerController will change to webViewerController.
 */
- (void)ampPageViewController:(AMPKViewer *)ampPageViewController
    willChangeCurrentAmpWebViewerControllerTo:(AMPKWebViewerViewController *)webViewerController;

/**
 * Notifies the delegate that currentAmpWebViewerController has been changed.
 */
- (void)ampPageViewControllerDidChangeCurrentAmpWebViewerController:
    (AMPKViewer *)ampPageViewController;

/**
 * Notifies the delegate that viewerDataSource has been changed.
 */
- (void)ampPageViewControllerDidChangeViewerDataSource:
    (AMPKViewer *)ampPageViewController;

@end
