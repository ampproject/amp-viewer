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

#import "AMPKViewController.h"

#import <SafariServices/SafariServices.h>

#import "AMPK.h"
#import "AMPKHeaderView.h"
#import "MaterialButtons.h"

@interface AMPKViewController () <AMPKPresenterProtocol,
                                  AMPKWebViewerViewControllerDelegate,
                                  AMPKViewerDelegate>

@property(nonatomic) AMPKHeaderView *headerView;

@end

@implementation AMPKViewController

@dynamic presenter;
@dynamic pageViewControllerDelegate;

#pragma mark - Initialization

- (instancetype)initWithViewerDataSource:(AMPKViewerDataSource *)viewerDataSource {
  self = [super initWithViewerDataSource:viewerDataSource];
  if (self) {
    _headerView = [AMPKHeaderView ampHeaderView];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  super.pageViewControllerDelegate = self;
  super.presenter = self;
  self.headerView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.headerView];

  [self.headerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor].active = YES;
  [self.headerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor].active = YES;
  [self.headerView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
  [self.headerView.heightAnchor constraintEqualToConstant:65].active = YES;
  self.headerView.topLayoutGuide = self.topLayoutGuide;

  [self.headerView.closeButton addTarget:self
                                  action:@selector(closeViewer:)
                        forControlEvents:UIControlEventTouchUpInside];

  [self.headerView.shareButton addTarget:self
                                  action:@selector(shareURL:)
                        forControlEvents:UIControlEventTouchUpInside];

  self.currentAmpWebViewerController.webScrollView.contentInset = [self headerContentInset];
}

#pragma mark - AMPKViewerDelegate

- (void)ampPageViewControllerDidChangeCurrentAmpWebViewerController:
    (AMPKViewer *)ampPageViewController {
  self.currentAmpWebViewerController.delegate = self;
  [self updateHeader];
}

- (void)ampPageViewControllerDidChangeViewerDataSource:
    (AMPKViewer *)ampPageViewController {
  [self updateHeaderViewPageControlAppearance];
}

- (void)ampPageViewController:(AMPKViewer *)ampPageViewController
    willChangeCurrentAmpWebViewerControllerTo:(AMPKWebViewerViewController *)webViewerController {
  UIScrollView *webScrollView = webViewerController.webScrollView;
  // If the webView is scrolled all the way to the top, then we should move it into the visible
  // range.
  BOOL setOffset = -webScrollView.contentOffset.y == webScrollView.contentInset.top;
  webScrollView.contentInset = [self headerContentInset];
  if (setOffset) {
    webScrollView.contentOffset =
        CGPointMake(webScrollView.contentOffset.x, -webScrollView.contentInset.top);
  }
}

- (void)ampWebViewerDidChangeHeaderInfo:(AMPKWebViewerViewController *)ampWebViewController {
  if (ampWebViewController == self.currentAmpWebViewerController) {
    [self updateHeader];
  }
}

#pragma mark - Target Action

- (void)closeViewer:(id)sender {
  [self.AMPKViewControllerDelegate AMPKCloseViewer:sender];
}

- (void)shareURL:(id)sender {
  NSArray *item = @[self.currentAmpWebViewerController.article.canonicalURL];
  UIActivityViewController *activityViewController =
      [[UIActivityViewController alloc] initWithActivityItems:item
                                        applicationActivities:nil];
  activityViewController.completionWithItemsHandler = ^(NSString *activityType,
                                                        BOOL completed,
                                                        NSArray *returnedItems,
                                                        NSError *activityError) {
    SEL shareCompletionHandler = @selector(shareCompletionWithItemsHandler);
    if ([self.AMPKViewControllerDelegate respondsToSelector:shareCompletionHandler]) {
      self.AMPKViewControllerDelegate.shareCompletionWithItemsHandler(activityType,
                                                                      completed,
                                                                      returnedItems,
                                                                      activityError);
    }
  };
  [self presentViewController:activityViewController animated:YES completion:nil];
}


#pragma mark - Presenter Protocol

- (void)presentEmbeddedLinkRequest:(NSURLRequest *)embeddedLinkRequest
                fromViewController:(UIViewController *)fromViewController {
  NSURL *url = embeddedLinkRequest.URL;
  if ([self.AMPKViewControllerDelegate respondsToSelector:@selector(AMPKPresentExternalURL:)]) {
    [self.AMPKViewControllerDelegate AMPKPresentExternalURL:url];
  } else {
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
    [self presentViewController:safariViewController animated:YES completion:nil];
  }
}

- (void)presentAccessUrl:(NSURL *)accessUrl
           requestPrefix:(NSString *)identifier
               requestId:(NSString *)requestId
      fromViewController:(UIViewController<AMPKPaywallAccessProtocol> *)fromViewController {
  // TODO: Implement correctly in AMPKit.
}

#pragma mark - Update Header

- (void)updateHeader {
  [UIView animateWithDuration:0.25 animations:^{
    self.headerView.urlLabel.text =
        [self headerStringForURL:self.currentAmpWebViewerController.article.publisherURL];
    [self.headerView layoutIfNeeded];
  }];
  self.headerView.pageControl.currentPage =
      [self.viewerDataSource indexForViewController:self.currentAmpWebViewerController];
}

- (void)updateHeaderViewPageControlAppearance {
   self.headerView.pageControl.numberOfPages = self.viewerDataSource.count;
   self.headerView.pageControl.hidden = self.viewerDataSource.count <= 1;
}

#pragma mark - Private

- (NSString *)headerStringForURL:(NSURL *)url {
  return [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
}

- (UIEdgeInsets)headerContentInset {
  return UIEdgeInsetsMake(CGRectGetMaxY(self.headerView.frame), 0, 0, 0);
}

@end
