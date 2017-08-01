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

#import "AKDAmpViewer.h"

#import "AMPK.h"
#import "AKDHeader.h"

#import <SafariServices/SafariServices.h>

@interface AKDAmpViewer () <AMPKWebViewerViewControllerDelegate>
@end

@implementation AKDAmpViewer {
  AKDHeader *_headerView;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.pageViewControllerDelegate = self;
  self.presenter = self;

  _headerView = [[AKDHeader alloc] initWithTitle:nil atURL:nil];
  _headerView.translatesAutoresizingMaskIntoConstraints = NO;
  _headerView.backgroundColor = [UIColor lightGrayColor];

  [[self view] addSubview:_headerView];

  [_headerView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor].active = YES;

  [_headerView.heightAnchor constraintEqualToConstant:80].active = YES;

  [_headerView.topAnchor constraintEqualToAnchor:self.topLayoutGuide.bottomAnchor
                                        constant:-20].active = YES;

  [[_headerView closeButton] addTarget:self
                                action:@selector(closeViewer)
                      forControlEvents:UIControlEventTouchUpInside];
  [[_headerView shareButton] addTarget:self
                                action:@selector(shareArticle)
                      forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - AMPKViewerDelegate methods

- (void)ampWebViewerDidChangeHeaderInfo:(AMPKWebViewerViewController *)ampWebViewController {
  _headerView.title = self.currentAmpWebViewerController.title;
  _headerView.url = self.currentAmpWebViewerController.article.publisherURL;
  [_headerView updateLabels];
}

- (void)ampPageViewControllerDidChangeViewerDataSource:
    (AMPKViewer *)ampViewer {
}

- (void)ampPageViewControllerDidChangeCurrentAmpWebViewerController:
    (AMPKViewer *)ampViewer {
  // If you have a header, it's important to set this delegate on the currentAmpWebViewerController
  // otherwise you'll miss out on title changes
  self.currentAmpWebViewerController.delegate = self;
  _headerView.title = self.currentAmpWebViewerController.title;
  _headerView.url = self.currentAmpWebViewerController.article.publisherURL;
  [_headerView updateLabels];
}

- (void)ampPageViewController:(AMPKViewer *)ampPageViewController
    willChangeCurrentAmpWebViewerControllerTo:(AMPKWebViewerViewController *)webViewerController {
  UIScrollView *webScrollView = webViewerController.webScrollView;
  BOOL setOffset = -webScrollView.contentOffset.y == webScrollView.contentInset.top;
  webScrollView.contentInset = UIEdgeInsetsMake(CGRectGetHeight(_headerView.bounds), 0, 0, 0);
  if (setOffset) {
    webScrollView.contentOffset =
    CGPointMake(webScrollView.contentOffset.x, -webScrollView.contentInset.top);
  }
}

#pragma mark = GMOAmpPresenterProtocol methods

- (void)presentEmbeddedLinkRequest:(NSURLRequest *)embeddedLinkRequest
                fromViewController:(UIViewController *)fromViewController {
  SFSafariViewController *safariViewController =
      [[SFSafariViewController alloc] initWithURL:[embeddedLinkRequest URL]];
  [self presentViewController:safariViewController animated:YES completion:NULL];
}

// TODO(stephen-deg): Update demo when Paywall support is fully added.
- (void)presentAccessUrl:(NSURL *)accessUrl
           requestPrefix:(NSString *)identifier
               requestId:(NSString *)requestId
      fromViewController:(UIViewController<AMPKPaywallAccessProtocol> *)fromViewController {
}

#pragma mark - UIPageViewControllerDelegate

// You may override the willTransition and didFinishAnimating pageViewController methods to add more
// functionality. Just be sure to call super.
- (void)pageViewController:(UIPageViewController *)pageViewController
    willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
  [super pageViewController:pageViewController
      willTransitionToViewControllers:pendingViewControllers];
}

#pragma mark - Button action targets

- (void)closeViewer {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)shareArticle {
  NSURL *shareURL = self.currentAmpWebViewerController.article.publisherURL;
  UIActivityViewController *shareSheet =
      [[UIActivityViewController alloc] initWithActivityItems:@[shareURL]
                                        applicationActivities:nil];

  [self presentViewController:shareSheet animated:YES completion:NULL];
}

@end
