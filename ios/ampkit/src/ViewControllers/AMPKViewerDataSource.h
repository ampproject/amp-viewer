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

#import "AMPKArticleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AMPKViewerDataSource;
@protocol AMPKViewerDataSourceDelegate <NSObject>

/** Notifies delegate that dataSource has been changed. */
- (void)ampViewerDataSourceDidChange:(AMPKViewerDataSource *)dataSource;
@end

@class AMPKWebViewerViewController;

@interface AMPKViewerDataSource : NSObject <UIPageViewControllerDataSource, NSCoding, NSCopying>

@property(nonatomic, weak) id<AMPKViewerDataSourceDelegate> delegate;

/**
 * The current number of AMP URL's represented in this data source.
 */
@property(nonatomic, readonly) NSUInteger count;

/**
 * Any datasource needs to expose all the AMP Views which are currently in the "pre-loaded" state.
 * This is required to support the broadcast feature of the AMP Runtime which must track all loaded
 * AMP Views in order to forward messages to views which have already been loaded and will not be
 * reloaded before being shown to the user.
 */
@property(nonatomic, readonly) NSSet <AMPKWebViewerViewController *> *allLoadedViewControllers;

/**
 * Designated init method.
 * @param domainName form as https://xxx.google.com/.
 */
- (instancetype)initWithDomainName:(NSURL *)domainName NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Sets the current AMP Articles being used by this datasource to provide to the WebViews.
 * @param articles The articles to set.
 * @param headers The headers to set in the HTTP request made for each of the @c articles. The
 * key of the dictionary should be the header field and the value of the dictionary the value of the
 * header field.
 */
- (void)setAmpArticles:(NSArray<id<AMPKArticleProtocol>> *)articles
          usingHeaders:(nullable NSDictionary *)headers;

/** Updates current index for visible view controller. */
- (void)setCurrentVisibleIndex:(NSInteger)index;

/**
 * Starts the pre-loading of the "next" view controller. Call this as soon as scrolling begins in
 * any direction in order to ensure the "next" view controller is pre-loaded and ready for fast
 * swiping.
 */
- (void)prefetchItemAtIndex:(NSInteger)index;

/**
 * Queries the index for a particular viewController. */
- (NSInteger)indexForViewController:(UIViewController *)viewController;

/**
 * Queries viewController via subscripting style. Return nil if index is out of
 * bounds.
 */
- (AMPKWebViewerViewController *)objectAtIndexedSubscript:(NSInteger)index;

@end

/** Private header to expose internal methods for unit tests. */
@interface AMPKViewerDataSource ()

- (BOOL)areArticlesSimilar:(NSArray<id<AMPKArticleProtocol>> *)articles;

@end

NS_ASSUME_NONNULL_END
