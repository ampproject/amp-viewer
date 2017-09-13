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

#import "AMPKViewer.h"

#import "AMPKMessageBroadcaster.h"
#import "AMPKViewerDataSource.h"
#import "AMPKWebViewerViewController.h"

@interface AMPKViewer () <AMPKViewerDataSourceDelegate>

@property(nonatomic) NSInteger currentViewerIndex;

@end

@implementation AMPKViewer {
  AMPKMessageBroadcaster *_messageBroadcaster;
}

- (instancetype)initWithViewerDataSource:(AMPKViewerDataSource *)viewerDataSource {
  self = [super initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                  navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                options:nil];
  if (self) {
    _viewerDataSource = viewerDataSource;
    _viewerDataSource.delegate = self;

    self.dataSource = _viewerDataSource;
    self.delegate = self;

    _currentViewerIndex = NSNotFound;

    _messageBroadcaster = [[AMPKMessageBroadcaster alloc] init];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  [_currentAmpWebViewerController setVisible:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];

  [_currentAmpWebViewerController setVisible:NO];
}

#pragma mark Public

- (void)setCurrentViewerIndex:(NSInteger)currentViewerIndex {
  if (_currentViewerIndex != currentViewerIndex) {
    [self resetVisibleAmpViewerControllerAtIndex:currentViewerIndex];
  }
}

- (void)setPresenter:(id<AMPKPresenterProtocol>)presenter {
  _presenter = presenter;
  self.currentAmpWebViewerController.presenter = _presenter;
}

- (void)setIsPrefetched:(BOOL)isPrefetched {
  if (isPrefetched == _isPrefetched) return;

  _isPrefetched = isPrefetched;
  if (!isPrefetched) {
    [_currentAmpWebViewerController setVisible:YES];
  }
}

#pragma mark - State Restoration

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
  [super encodeRestorableStateWithCoder:coder];

  [coder encodeObject:_viewerDataSource forKey:@"_viewerDataSource"];
  [coder encodeInteger:_currentViewerIndex forKey:@"_currentViewerIndex"];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
  [super decodeRestorableStateWithCoder:coder];

  _viewerDataSource = [coder decodeObjectForKey:@"_viewerDataSource"];
  _viewerDataSource.delegate = self;
  self.dataSource = _viewerDataSource;
  [_pageViewControllerDelegate ampPageViewControllerDidChangeViewerDataSource:self];

  [self resetVisibleAmpViewerControllerAtIndex:[coder decodeIntegerForKey:@"_currentViewerIndex"]];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController
    willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
  AMPKWebViewerViewController *willTransitionController =
      (AMPKWebViewerViewController *)pendingViewControllers.firstObject;
  [willTransitionController setVisible:YES];

  NSInteger index = [_viewerDataSource indexForViewController:willTransitionController];
  [_viewerDataSource prefetchItemAtIndex:index];

  [_pageViewControllerDelegate ampPageViewController:self
           willChangeCurrentAmpWebViewerControllerTo:willTransitionController];
}

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
       transitionCompleted:(BOOL)completed {
  if (!completed) {
    return;
  }
  self.isPrefetched = NO;

  NSAssert(_currentAmpWebViewerController == previousViewControllers.firstObject,
            @"currentAmpWebViewController %@ must be in preivousViewController %@",
            _currentAmpWebViewerController, previousViewControllers);

  NSInteger index =
      [_viewerDataSource indexForViewController:pageViewController.viewControllers.firstObject];
  [self resetVisibleAmpViewerControllerAtIndex:index];
}

#pragma mark - AMPKViewerDataSourceDelegate

- (void)ampViewerDataSourceDidChange:(AMPKViewerDataSource *)dataSource {
  if (_currentViewerIndex > dataSource.count) {
    // Reset viewerIndex if it is out of bounds.
    _currentViewerIndex = 0;
  }

  [self resetVisibleAmpViewerControllerAtIndex:_currentViewerIndex];
  [_pageViewControllerDelegate ampPageViewControllerDidChangeViewerDataSource:self];
}

#pragma mark - AMP Runtime Extension endpoints

- (void)setPagingEnabled:(BOOL)enabled {
  for (UIView *view in self.view.subviews) {
    if ([view isKindOfClass:[UIScrollView class]]) {
      UIScrollView *scrollView = (UIScrollView *)view;
      [scrollView setScrollEnabled:enabled];
    }
  }
}

// The base page view controller doesn't provide a header. Any subclass specific AMP viewer should
// override this method to control the visible of its header as requested by the runtime.
- (void)setHeaderVisible:(BOOL)visible {
}

#pragma mark - Private

// Reset the current visible AMP viewer to be at a givin index.
- (void)resetVisibleAmpViewerControllerAtIndex:(NSInteger)index {
  UIScrollView *previousScrollView = _currentAmpWebViewerController.webScrollView;
  previousScrollView.scrollsToTop = NO;

  _currentViewerIndex = index;
  _currentAmpWebViewerController = _viewerDataSource[index];
  _currentAmpWebViewerController.presenter = self.presenter;
  _currentAmpWebViewerController.viewer = self;

  UIScrollView *webScrollView = _currentAmpWebViewerController.webScrollView;

  // ScrollView delegate needs to multiplex because it allows other object to be its delegate to
  // perform dismissal animation.
  webScrollView.scrollsToTop = YES;

  [_viewerDataSource setCurrentVisibleIndex:index];

  // WKWebView won't pre-render any view if it is not within window. Thus, we force to it to be
  // pre-render here.
  AMPKWebViewerViewController *before = _viewerDataSource[index - 1];
  if (before) {
    if (!before.view.window) {
      [self.view insertSubview:before.view atIndex:0];
    }
    [before setVisible:NO];
  }

  AMPKWebViewerViewController *after = _viewerDataSource[index + 1];
  if (after) {
    if (!after.view.window) {
      [self.view insertSubview:after.view atIndex:0];
    }
    [after setVisible:NO];
  }

  if (![self.viewControllers containsObject:_currentAmpWebViewerController] &&
      _currentAmpWebViewerController) {
    [self setViewControllers:@[_currentAmpWebViewerController]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:nil];
    // Since this happens if the AMP VC isn't in the list of views, then the AMP VC did not go
    // receive its setVisible call so we should manually set that.
    [_currentAmpWebViewerController setVisible:YES];
  }

  [_pageViewControllerDelegate ampPageViewControllerDidChangeCurrentAmpWebViewerController:self];
  NSMutableSet<AMPKWebViewerMessageHandlerController *> *controllers =
      [[NSMutableSet alloc] init];
  [[_viewerDataSource allLoadedViewControllers] enumerateObjectsUsingBlock:
       ^(AMPKWebViewerViewController * _Nonnull viewController, BOOL * _Nonnull stop) {
         [controllers addObject:viewController.messageHandlerController];
  }];
  [_messageBroadcaster setLoadedControllers:controllers];
}

#pragma mark - Accessibility

// If the user attempts a voice over accessibility scroll detect and reset the viewer to the
// correct index.
- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  if (direction == UIAccessibilityScrollDirectionRight ||
      direction == UIAccessibilityScrollDirectionLeft) {
    NSInteger indexOffset = (direction == UIAccessibilityScrollDirectionRight ? -1 : 1);
    NSInteger newViewerIndex = _currentViewerIndex + indexOffset;
    if (newViewerIndex >= 0 && newViewerIndex < [_viewerDataSource count]) {
      [self resetVisibleAmpViewerControllerAtIndex:newViewerIndex];
      return YES;
    }
  }

  return NO;
}

@end
