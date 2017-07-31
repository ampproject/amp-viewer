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

#import "AMPKArticleProtocol.h"
#import "AMPKPresenterProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AMPKViewer;
@class AMPKWebViewerMessageHandlerController;
@class AMPKWebViewerJsMessage;
@class AMPKWebViewerViewController;
@class WKWebView;

@protocol AMPKWebViewerViewControllerDelegate <NSObject>

@optional

/** Notify delegate that current AMP viewer's header information has been changed. */
- (void)ampWebViewerDidChangeHeaderInfo:(AMPKWebViewerViewController *)ampWebViewController;

/** Notify delegate that current AMP viewer did finish loading. */
- (void)ampWebViewerDidFinishRendering:(AMPKWebViewerViewController *)ampWebViewController;

@end

/** AMPKWebViewerViewController renders a particular ampUrl via WKWebView. */
@interface AMPKWebViewerViewController : UIViewController <AMPKPaywallAccessProtocol>

@property(nonatomic, strong, readonly) NSURL *webURL;

@property(nonatomic, readonly) WKWebView *webView;

@property(nonatomic, weak, nullable) id<AMPKPresenterProtocol> presenter;

@property(nonatomic, weak, nullable) id<AMPKWebViewerViewControllerDelegate> delegate;

@property(nonatomic, weak, nullable) AMPKViewer *viewer;

@property(nonatomic, readonly) UIScrollView *webScrollView;

@property(nonatomic, readonly) AMPKWebViewerMessageHandlerController *messageHandlerController;

/**
 * This is the URL that represents the article at the publisher's site. This should never be used
 * to set the webview URL or to share articles.
 */
@property(nonatomic, readonly, nullable) id<AMPKArticleProtocol> article;

/**
 * This is used to hide the web view. Generally, users should call setVisible rather than directly
 * set the hidden property on the web view. This will send the appropriate visibility state
 * change message to the AMP runtime in addition to setting the appropriate hidden value on the web
 * view.
 */
@property(nonatomic) BOOL visible;

/**
 * Designated init method.
 * @param domainName form as https://xxx.google.com/.
 */
- (instancetype)initWithDomainName:(NSURL *)domainName NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithNibName:(nullable NSString *)nibNameOrNil
                         bundle:(nullable NSBundle *)nibBundleOrNil NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;

/**
 * This should be called to start loading a new AMP Article.
 * @param article The AMP article to load.
 * @param headers The headers to set in the HTTP request made for the @c article. The key of the
 * dictionary should be the header field and the value of the dictionary the value of the header
 * field.
 */
- (void)loadAmpArticle:(id<AMPKArticleProtocol>)article
           withHeaders:(nullable NSDictionary<NSString *, NSString *> *)headers;

@end

/** Class extension for supporting web navigation. */
@interface AMPKWebViewerViewController ()

/** Check whether it can go forward. Return YES if it can go forward. */
- (BOOL)checkCanGoForward;

/** Return YES if it can go forward and it did. Otherwise, return NO. */
- (BOOL)goForwardIfPossible;

/** Return YES if it can go forward and it did. Otherwise, return NO. */
- (BOOL)checkCanGoBack;

/** Return YES if it can go back and it did. Otherwise, return NO. */
- (BOOL)goBackIfPossible;

@end

NS_ASSUME_NONNULL_END
