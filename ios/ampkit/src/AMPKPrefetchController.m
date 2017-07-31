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

#import "AMPKPrefetchController.h"

#import "AMPKViewer.h"
#import "AMPKViewerDataSource.h"


NS_ASSUME_NONNULL_BEGIN

@implementation AMPKPrefetchController

@synthesize ampViewController = _ampViewController;

#pragma mark - Prefetching Viewer

- (void)ampViewerWithArticles:(NSArray<id <AMPKArticleProtocol>> *)articles
                 usingHeaders:(nullable NSDictionary<NSString *, NSString *> *)headers
            prefetchedAtIndex:(NSInteger)index {
  // Note the AMP datasource will not reset the data source if the new array is equal to the
  // current array, so it is safe to set this in prefetch without checking that the arrays are not
  // equal.
  NSMutableArray<id<AMPKArticleProtocol>> *validArticles =
      [[NSMutableArray alloc] initWithCapacity:articles.count];
  for (id<AMPKArticleProtocol> article in articles) {
    if (AMPKArticleIsValid(article)) {
      [validArticles addObject:article];
    }
  }
  [self.ampViewController.viewerDataSource setAmpArticles:validArticles usingHeaders:headers];
  [self.ampViewController setCurrentViewerIndex:index];
}

#pragma mark - Opening Viewer

- (void)updatePrefetchIndex:(NSInteger)index {
  [self.ampViewController setCurrentViewerIndex:index];
}

- (void)abandonPrefetchedViewer {
   AMPKViewerDataSource *dataSource = [self.ampViewController.viewerDataSource copy];
   _ampViewController = [self createViewerForDataSource:dataSource];
   [_ampViewController setCurrentViewerIndex:0];
}

#pragma mark - Property getter overrides

// Lazy load the ampViewController.
- (AMPKViewer *)ampViewController {
  if (!_ampViewController) {
    AMPKViewerDataSource *dataSource;
    if ([self.prefetchProvider respondsToSelector:@selector(defaultDataSource)]) {
      dataSource = [self.prefetchProvider defaultDataSource];
    } else {
      NSURL *defaultURL = [NSURL URLWithString:@"https://www.google.com"];
      dataSource = [[AMPKViewerDataSource alloc] initWithDomainName:defaultURL];
    }
    NSAssert(dataSource, @"The AMPKViewerDataSource cannot be nil");
    _ampViewController = [self createViewerForDataSource:dataSource];
  }
  return _ampViewController;
}

#pragma mark - Private

// Creates a new AMP viewer with the given data source and then calls the analytics provider if one
// is available to setup an alaytics object for use.
- (AMPKViewer *)createViewerForDataSource:(AMPKViewerDataSource *)dataSource {
  AMPKViewer *ampViewer;
  if ([self.prefetchProvider respondsToSelector:@selector(newViewerWithDataSource:)]) {
    ampViewer = [self.prefetchProvider newViewerWithDataSource:dataSource];
  } else {
    ampViewer = [[AMPKViewer alloc] initWithViewerDataSource:dataSource];
  }
  return ampViewer;
}

@end

NS_ASSUME_NONNULL_END
