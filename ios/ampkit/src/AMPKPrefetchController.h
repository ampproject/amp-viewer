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

@class AMPKViewer;
@class AMPKViewerDataSource;
@protocol AMPKAnalyticsProtocol;
@protocol AMPKArticleProtocol;

NS_ASSUME_NONNULL_BEGIN

/**
 * A protocol which allows for users of the AMPKPrefetchController to provide customized objects
 * for use when displaying the AMP viewer.
 */
@protocol AMPKPrefetchProvider <NSObject>

@optional

/**
 * Return a AMPKViewerDataSource with the proper viewer URL based on the user's location. See
 * AMPKViewerDataSource initWithDomainName for more details. If this is not implemented, AmpKit will
 * default to https://www.google.com
 */
- (AMPKViewerDataSource *)defaultDataSource;

/**
 * Return a new instance of the AMPViewer you wish to use given the @c dataSource. You should
 * implement if you have a cusomtized AMPKViewer. If not implememnted, will use the default viewer.
 * @param dataSource The @c AMPKViewerDataSource that should be used for the instance of the viewer
 * you return.
 */
- (AMPKViewer *)newViewerWithDataSource:(AMPKViewerDataSource *)dataSource;

@end

/**
 * This class provides a generic prefetch controller for AMPKit. Use this class when you need the
 * ability to show/hide the AMP viewer with different data sets (ie, different sets of AMP articles)
 * or when you want to preload the AMP viewer so it is loaded and ready to go when it is presented.
 */
@interface AMPKPrefetchController : NSObject

/* The current AMP viewer if one has been initialized. **/
@property(nonatomic, readonly) AMPKViewer *ampViewController;

/**
 * A delegate to provide the custom Analytics object for use in the AMP viewer.
 * This delegate is optional. If you do not need to use any sort of Analytics with this AMP viewer
 * there is no need to provide this delegate.
 */
@property(nonatomic, weak) id<AMPKPrefetchProvider> prefetchProvider;

/**
 * Call this method with an array of valid AMP articles and the desired index to prefetch.
 * @param articles The articles conforming to AMPKArticleProtocol that should be opened.
 * @param headers The headers to set in the HTTP request made for each of the @c articles. The
 * key of the dictionary should be the header field and the value of the dictionary the value of the
 * header field.
 * @param index The index you would like to preload the viewer to.
 * @note Please call super when subclassing this method. Calling this method more than once with the
 * same data source will not result in setting the data source more than once, but the @c index will
 * be respected if it is different than the current index.
 */
- (void)ampViewerWithArticles:(NSArray<id <AMPKArticleProtocol>> *)articles
                 usingHeaders:(nullable NSDictionary<NSString *, NSString *> *)headers
            prefetchedAtIndex:(NSInteger)index NS_REQUIRES_SUPER;

/**
 * Call this method to change the pre-fetched index. You may call this before presenting the AMP
 * viewer to make sure the viewer is loaded on the correct article.
 * @param index The index of the article to set as the current AMP article in the @c
 * ampViewController.
 */
- (void)updatePrefetchIndex:(NSInteger)index;

/**
 * This will create a copy of the current @c ampViewController and abandon the current viewer.
 * You can call this if you need to keep the current @ampViewController for some reason but
 * wish to have a new viewer available via the prefetch controller.
 */
- (void)abandonPrefetchedViewer;

@end

NS_ASSUME_NONNULL_END
