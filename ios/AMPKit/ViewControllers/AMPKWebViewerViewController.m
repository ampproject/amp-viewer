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

#import <WebKit/WebKit.h>

#import "AMPKViewer.h"
#import "AMPKWebViewerJsMessage.h"
#import "AMPKWebViewerMessageHandlerController.h"
#import "AMPKRuntimeUtilities.h"
#import "AMPKWebViewerViewController_private.h"
#import "NSURL+AMPK.h"

#import "MaterialActivityIndicator.h"

NS_ASSUME_NONNULL_BEGIN

static void * kAMPKWebViewerKVOContext = &kAMPKWebViewerKVOContext;
static NSString *const kLinkRelsDocumentLoaded = @"linkRels";
static NSString *const kCanonicalDocumentLoaded = @"canonical";
NSString * const AMPKHeaderNameField = @"X-AMP-VIEWER";

@interface AMPKWebViewerViewController ()
@property(nonatomic, nullable) id<AMPKArticleProtocol> article;

@property(nonatomic, readwrite, nullable) NSURL *sharingURL;
@end

@implementation AMPKWebViewerViewController {
  MDCActivityIndicator *_activityIndicator;
  BOOL _hasInitialContentOffset;
  CGPoint _initialContentOffset;

  // There is no easy way to reset WKWebView history state. As a result, we compare
  // currentItem.initURL and use a ivar to keep track of it.
  BOOL _canGoBackward;

  AMPKWebViewerMessageHandlerController *_messageHandlerController;

  NSURL *_domainName;
}

- (instancetype)initWithDomainName:(NSURL *)domainName {
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _messageHandlerController = [[AMPKWebViewerMessageHandlerController alloc] init];
    _messageHandlerController.ampWebViewerController = self;
    _domainName = [domainName copy];
  }
  return self;
}

- (void)dealloc {
  [_webView removeObserver:self forKeyPath:@"loading"];
  [_webView removeObserver:self forKeyPath:@"title"];
  [_webView removeObserver:self forKeyPath:@"URL"];
  _webView.navigationDelegate = nil;
  _webView.scrollView.delegate = nil;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
  _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
  _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

  [_webView addObserver:self forKeyPath:@"loading" options:0 context:&kAMPKWebViewerKVOContext];
  [_webView addObserver:self forKeyPath:@"title" options:0 context:&kAMPKWebViewerKVOContext];
  [_webView addObserver:self forKeyPath:@"URL" options:0 context:&kAMPKWebViewerKVOContext];

  _webView.navigationDelegate = _messageHandlerController;

  _activityIndicator = [[MDCActivityIndicator alloc] initWithFrame:CGRectZero];
  [_activityIndicator sizeToFit];

  self.view.backgroundColor = [UIColor whiteColor];
  [self.view addSubview:_activityIndicator];
  [self.view addSubview:_webView];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];

  _webView.hidden = _webView.loading;

  CGRect bounds = self.view.bounds;
  _activityIndicator.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  if (_webView.loading) {
    [_activityIndicator startAnimating];
  }
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];

  [_activityIndicator stopAnimating];
}

#pragma mark - Public

- (void)setViewerContentOffset:(CGPoint)viewerContentOffset {
  if (!CGPointEqualToPoint(_initialContentOffset, viewerContentOffset)) {
    _initialContentOffset = viewerContentOffset;
    if (!_webView.loading) {
      self.webScrollView.contentOffset = _initialContentOffset;
    } else {
      _hasInitialContentOffset = YES;
    }
  }
}

- (CGPoint)viewerContentOffset {
  return self.webScrollView.contentOffset;
}

- (UIScrollView *)webScrollView {
  return _webView.scrollView;
}

- (NSURL *)webURL {
  return _webView.URL;
}

- (void)setVisible:(BOOL)visible {
  if (self.viewer.isPrefetched) {
    [_messageHandlerController sendPrefetched];
    _visible = NO;
    self.view.hidden = NO;
  } else {
    [_messageHandlerController sendVisible:visible];
    _visible = visible;
    // We should hide the entire view controller when it's not being presented. The view
    // controller's main view will have hidden set to NO as soon as the page view controller begins
    // to page but before the view is ever shown to the user so there is no visible difference.
    // This, however, resolves an issue where the view was visible because we force it into the
    // hierarchy for pre-fetching and was visible "behind" the current view controller if you
    // attempt to swipe beyond the view controller at the end (either index 0 or n-1).
    self.view.hidden = !visible;
  }
}

- (void)loadAmpArticle:(id<AMPKArticleProtocol>)article
           withHeaders:(nullable NSDictionary<NSString *, NSString *> *)headers {
  if ([self.article.publisherURL isEqual:article.publisherURL]) {
    return;
  }

  self.article = [article copyWithZone:nil];

  _canGoBackward = YES;

  ((void)([self view]));  // Force to load view.

  NSAssert(self.article.publisherURL.host,
             @"Must have a valid Host for AMP URL: %@",
             self.article.publisherURL);
  _messageHandlerController.source = [self proxiedURL];
  _messageHandlerController.ampWebViewerController = self;

  NSURL *url = [[self proxiedURL] URLBySettingProxyHashFragmentsForDomain:_domainName];
  NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
  if (!headers[AMPKHeaderNameField]) {
    [urlRequest setValue:[NSBundle mainBundle].bundleIdentifier
      forHTTPHeaderField:AMPKHeaderNameField];
  }
  [headers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key,
                                               NSString * _Nonnull obj,
                                               BOOL * _Nonnull stop) {
    if ([key isKindOfClass:[NSString class]] &&
        [obj isKindOfClass:[NSString class]] &&
        obj.length > 0 &&
        key.length > 0) {
      [urlRequest setValue:obj forHTTPHeaderField:key];
    }
  }];
  [_webView loadRequest:urlRequest];
}


- (void)prepareForReuse {
  self.webView.hidden = YES;
  self.title = nil;
  self.article = nil;
  _canGoBackward = NO;
  _viewerDataSourceIndex = NSNotFound;

  _initialContentOffset = CGPointZero;
  _hasInitialContentOffset = NO;

  [_activityIndicator stopAnimating];
  _messageHandlerController.ampWebViewerController = nil;
  _ampJsReady = NO;

  _presenter = nil;
  _delegate = nil;
}

#pragma mark - Paywall Access

- (void)paywallAccessCompletionWithToken:(NSString *)token requestId:(NSString *)requestId {
  AMPKWebViewerJsMessage *replyMessage =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeResponse
                                         name:@"openDialog"
                                    channelID:0
                                    requestID:[requestId integerValue]
                             responseRequired:NO
                                         data:token
                                originMessage:nil
                                        error:nil];
  [_messageHandlerController sendAmpJsMessage:replyMessage];
}

#pragma mark - Document/Viewer Initilization

- (void)channelOpenWithMessage:(AMPKWebViewerJsMessage *)message {
  AMPKWebViewerJsMessage *responseMessage =
      [AMPKWebViewerJsMessage messageWithType:AMPKMessageTypeResponse
                                         name:@"channelOpen"
                                    channelID:message.channelID
                                    requestID:message.requestID
                             responseRequired:NO
                                         data:@(YES)
                               originMessage:message
                                        error:nil];

  [_messageHandlerController sendAmpJsMessage:responseMessage];
}

- (void)AMPDocumentLoadedWithMessage:(AMPKWebViewerJsMessage *)message {
  self.ampJsReady = YES;
  // It's possible we attempted to set the visible message before the document was loaded if the
  // user is swiping very quickly. In this case, we need to re-send the visible message after the
  // document loaded has been received so that the runtime can load all the elements (ads, pictures
  // videos, ect). This also ensures we don't attempt to re-send a visibility status of "visible" to
  // an AMP article that was quickly scrolled off before the documentLoaded was received as such
  // views will be hidden as soon as they are swiped away.
  if (self.visible) {
    [_messageHandlerController sendVisible:YES];
  } else if (self.viewer.isPrefetched) {
    [_messageHandlerController sendPrefetched];
  }

  NSDictionary *data = AMPK_VERIFY_CLASS(message.data, NSDictionary);
  NSDictionary *linkRels = AMPK_VERIFY_CLASS(data[kLinkRelsDocumentLoaded], NSDictionary);
  NSString *canonicalURL = AMPK_VERIFY_CLASS(linkRels[kCanonicalDocumentLoaded], NSString);
  if (canonicalURL) {
    self.article.canonicalURL = [NSURL URLWithString:canonicalURL];
  }
}

- (void)requestFullOverlayMode {
  [self.viewer setPagingEnabled:NO];
  [self.viewer setHeaderVisible:NO];
}

- (void)cancelFullOverlayMode {
  [self.viewer setPagingEnabled:YES];
  [self.viewer setHeaderVisible:YES];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(nullable NSString *)keyPath
                      ofObject:(nullable id)object
                        change:(nullable NSDictionary *)change
                       context:(nullable void *)context {
  if (object == _webView && context == kAMPKWebViewerKVOContext) {
    if ([keyPath isEqualToString:@"loading"]) {
      if (_webView.loading) {
        [_activityIndicator startAnimating];
      } else {
        [_activityIndicator stopAnimating];
        [self loadingFinishedAnimation];
      }
      return;
    }

    if ([keyPath isEqualToString:@"title"]) {
      self.title = _webView.title;
      [self notifyDelegateDidChangeHeaderInfoIfNeeded];
      return;
    }

    if ([keyPath isEqualToString:@"URL"]) {
      [self notifyDelegateDidChangeHeaderInfoIfNeeded];
      return;
    }
  }

  [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - Spinner

- (void)loadingFinishedAnimation {
  if (_hasInitialContentOffset) {
    self.webScrollView.contentOffset = _initialContentOffset;
  }

  void (^animatingBlock)() = ^{
    _webView.alpha = 1.0;
  };
  void (^animationCompletion)(BOOL) = ^(BOOL finished) {
    _webView.hidden = NO;
    // Wait one runloop cycle to fire delegate call to allow view updates.
    [self performSelector:@selector(notifyDelegateDidFinishRenderingIfNeeded)
               withObject:nil
               afterDelay:0];
  };

  _webView.hidden = NO;
  _webView.alpha = 0.0;

  [UIView animateWithDuration:0.25 animations:animatingBlock completion:animationCompletion];
}

#pragma mark - Web Navigation support

- (BOOL)checkCanGoForward {
  return self.article.publisherURL != nil && [_webView canGoForward];
}

- (BOOL)goForwardIfPossible {
  return self.article.publisherURL != nil && [_webView goForward] != nil;
}

- (BOOL)checkCanGoBack {
  NSURL *publisherURL = self.article.publisherURL;
  return publisherURL && _canGoBackward &&
      ![_webView.backForwardList.currentItem.initialURL isEqual:publisherURL] &&
      _webView.canGoBack;
}

- (BOOL)goBackIfPossible {
  if (![self checkCanGoBack]) return NO;

  return [_webView goBack] != nil;
}

#pragma mark - Private

- (void)notifyDelegateDidChangeHeaderInfoIfNeeded {
  BOOL delegateImplements =
      [self.delegate respondsToSelector:@selector(ampWebViewerDidChangeHeaderInfo:)];
  if (delegateImplements && self.title && self.webURL) {
    [_delegate ampWebViewerDidChangeHeaderInfo:self];
  }
}

- (void)notifyDelegateDidFinishRenderingIfNeeded {
  BOOL delegateImplements =
      [self.delegate respondsToSelector:@selector(ampWebViewerDidFinishRendering:)];
  if (delegateImplements && self.webURL) {
    [_delegate ampWebViewerDidFinishRendering:self];
  }
}

- (nullable NSURL *)proxiedURL {
  return (self.article.cdnURL ?
          self.article.cdnURL : [self.article.publisherURL ampk_ProxiedURL]);
}

- (NSString *)description {
  return [NSString stringWithFormat:@"<%@: %p, index: %@, url: %@.>",
          NSStringFromClass([self class]),
          self,
          @(self.viewerDataSourceIndex),
          self.article.publisherURL];
}

@end

NS_ASSUME_NONNULL_END
