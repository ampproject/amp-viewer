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

#import "AMPKViewerDataSource.h"

#import "AMPKWebViewerViewController.h"
#import "AMPKWebViewerViewController_private.h"

NS_ASSUME_NONNULL_BEGIN

static const NSInteger kMaxAmpViewsToLoad = 4;

@implementation AMPKViewerDataSource {
  NSArray<id<AMPKArticleProtocol>> *_ampArticles;
  NSMutableSet<AMPKWebViewerViewController *> *_viewControllers;
  NSMutableSet<AMPKWebViewerViewController *> *_reuseableViewControllerPool;
  NSMutableDictionary<NSNumber *, NSValue *> *_recordedContentOffset;
  NSInteger _currentVisibleIndex;
  NSInteger _prefetchIndex;

  NSURL *_domainName;
  NSDictionary *_headers;
}

- (instancetype)initWithDomainName:(NSURL *)domainName {
  self = [super init];
  if (self) {
    _domainName = [domainName copy];
    _viewControllers = [NSMutableSet setWithCapacity:3];
    _reuseableViewControllerPool = [NSMutableSet setWithCapacity:3];
    _recordedContentOffset = [NSMutableDictionary dictionary];
    _currentVisibleIndex = NSNotFound;
    _prefetchIndex = NSNotFound;
  }
  return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [self initWithDomainName:[aDecoder decodeObjectForKey:@"_domainName"]];
  if (self) {
    _ampArticles = [aDecoder decodeObjectForKey:@"_ampArticles"];
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:_domainName forKey:@"_domainName"];
  [aCoder encodeObject:_ampArticles forKey:@"_ampArticles"];
}

- (NSUInteger)count {
  return [_ampArticles count];
}

- (void)setAmpArticles:(NSArray<id<AMPKArticleProtocol>> *)articles
          usingHeaders:(nullable NSDictionary *)headers {
  if ([self areArticlesSimilar:articles]) {
    return;
  }

  _ampArticles = [[NSArray alloc] initWithArray:articles copyItems:YES];
  _headers = headers;
  [_viewControllers enumerateObjectsUsingBlock:
       ^(AMPKWebViewerViewController *ampViewer, BOOL *stop) {
         [ampViewer prepareForReuse];
       }];
  [_recordedContentOffset removeAllObjects];
  [_reuseableViewControllerPool unionSet:_viewControllers];
  [_viewControllers removeAllObjects];

  [_delegate ampViewerDataSourceDidChange:self];
}

// Here we want to make sure that two AMPKArticleProtocol objects are the considered similar.
// Because other users could create their own model object and not implement the isEqual check
// correctly for the context of the viewer, it is more safe to manually check that both the
// Publisher's URL and the CDN URL are equal. From an AMP viewer perspective, we don't really care
// if the other custom fields in their model are equal or not.
- (BOOL)areArticlesSimilar:(NSArray<id<AMPKArticleProtocol>> *)articles {
  if (articles.count != _ampArticles.count) {
    return NO;
  } else if (_ampArticles == articles) {
    return YES;
  }

  BOOL (^areSimilar)(id<AMPKArticleProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) =
      ^BOOL(id<AMPKArticleProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<AMPKArticleProtocol> currentObj = _ampArticles[idx];
        // As soon as we find one object that is not equal bail early.
        if (!AMPKViewerShouldConsiderArticlesTheSame(currentObj, obj)) {
          return YES;
        }
        return NO;
      };
  return [articles indexOfObjectPassingTest:areSimilar] == NSNotFound;
}

- (void)setCurrentVisibleIndex:(NSInteger)index {
  if (_currentVisibleIndex != index) {
    _currentVisibleIndex = index;

    AMPKWebViewerViewController *before = self[index - 1];
    AMPKWebViewerViewController *current = self[index];
    AMPKWebViewerViewController *after = self[index + 1];

    NSMutableSet *viewControllers = [NSMutableSet setWithCapacity:3];
    if (before) {
      [viewControllers addObject:before];
    }
    if (current) {
      [viewControllers addObject:current];
    }
    if (after) {
      [viewControllers addObject:after];
    }

    // Determine which view controllers do not overlap with the 3 that will be active.
    [_viewControllers minusSet:viewControllers];

    NSSet *viewControllersToRecycle;
    // Keep a reference to these excess view controllers. We need them to determine after resetting
    // the |_viewControllers| set how many of them should be added to the reuse pool.
    NSUInteger totalCurrentViewControllers =
        _viewControllers.count + _reuseableViewControllerPool.count;
    if (_viewControllers.count > 0 && totalCurrentViewControllers < kMaxAmpViewsToLoad) {
      viewControllersToRecycle = [_viewControllers copy];
    }
    _viewControllers = viewControllers;
    // Then, if we have any VC's to recycle, recycle them.
    if (viewControllersToRecycle) {
      [self addToReusePool:viewControllersToRecycle];
    }

    _prefetchIndex = NSNotFound;

    NSAssert(_viewControllers.count + _reuseableViewControllerPool.count <= kMaxAmpViewsToLoad,
             @"total view out of sync");
  }
}

// For now, the loading of AMP views is tied to retrieving objects out of the datasource. In
// other words, everything is lazy-loaded when you request the article by its index. Therefore,
// in order to trigger the datasource to start loading the AMP view we want to pre-fetch, we
// need to request a view at that index. We don't do anything with it yet, as it will be
// returned to the PageViewController when the user finishes the swipe.
// TODO(stephen-deg): refactor the AMP view creation, re-use pool, and pre-fetching to exact it from
// the subscript support.
- (void)prefetchItemAtIndex:(NSInteger)index {
  NSInteger prefetchIndex = _currentVisibleIndex + (index < _currentVisibleIndex ? -2 : 2);
  if (prefetchIndex != _prefetchIndex) {
    AMPKWebViewerViewController *prefetchView = self[_prefetchIndex];
    if (prefetchView) {
      [_viewControllers removeObject:prefetchView];
      [self addToReusePool:[NSSet setWithObject:prefetchView]];
    }
    _prefetchIndex = prefetchIndex;

    // Here, we use the lazy loading trick described above to start the loading of the amp view that
    // needs to be pre-loaded. This datasource uses object subscripting to allow accessing amp views
    // by their index. So, the line below is simply triggering the loading of the prefetch index by
    // accessing that object index. Wrapping it in a void cast is simply to prevent any warnings.
    ((void)self[_prefetchIndex]);

    NSAssert(_viewControllers.count + _reuseableViewControllerPool.count <= kMaxAmpViewsToLoad,
            @"total view out of sync");
  }
}

// This method will add as many AMP Views to the reuse pool as it can while preserving the max
// number of AMP views that should be kept alive.
- (void)addToReusePool:(NSSet<AMPKWebViewerViewController *>*)addToPool {
  [addToPool enumerateObjectsUsingBlock:^(AMPKWebViewerViewController *ampViewer, BOOL *stop) {
    _recordedContentOffset[@(ampViewer.viewerDataSourceIndex)] =
        [NSValue valueWithCGPoint:ampViewer.viewerContentOffset];
  }];

  NSInteger totalPoolSize = kMaxAmpViewsToLoad - _viewControllers.count;
  NSInteger totalFreePoolSize = totalPoolSize - _reuseableViewControllerPool.count;

  // Only add views to the reuse pool if it's not already at capacity.
  if (totalFreePoolSize > 0) {
    addToPool = [self pruneSet:addToPool toMax:totalFreePoolSize];
    [addToPool enumerateObjectsUsingBlock:^(AMPKWebViewerViewController *ampViewer, BOOL *stop) {
      [ampViewer prepareForReuse];
    }];
    [_reuseableViewControllerPool unionSet:addToPool];

    NSAssert(_viewControllers.count + _reuseableViewControllerPool.count <= kMaxAmpViewsToLoad,
              @"total view out of sync");
  }
}

// This method will randomly prune the given set to a max size.
// NSSet doesn't have any defined order, so enumerating the set results in enumeration across all
// objects but in a non-guaranteed order. So if we prune a set of 3 objects to max size 2, the first
// two objects returned from the enumeration will be used, and the 3rd removed. However, we can't
// guarantee which one of the 3 will be removed.
- (NSSet *)pruneSet:(NSSet *)set toMax:(NSInteger)max {
  if (set.count <= max) {
    return set;
  }
  if (max <= 0) {
    return nil;
  }

  NSMutableSet *prunedSet = [[NSMutableSet alloc] initWithCapacity:max];
  [set enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
    [prunedSet addObject:obj];
    if (prunedSet.count == max) {
      *stop = YES;
    }
  }];

  return [prunedSet copy];
}

- (NSSet<AMPKWebViewerViewController *> *)allLoadedViewControllers {
  return [_viewControllers copy];
}

- (NSInteger)indexForViewController:(UIViewController *)viewController {
  NSAssert([viewController isKindOfClass:[AMPKWebViewerViewController class]],
            @"Expect viewController to AMPKWebViewController, instead it got %@", viewController);
  NSAssert([_viewControllers containsObject:(AMPKWebViewerViewController *)viewController],
            @"ViewController must be inside the viewControllers set.");

  return ((AMPKWebViewerViewController *)viewController).viewerDataSourceIndex;
}

#pragma mark - UIPageViewControllerDataSource

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController {
  return self[[self indexForViewController:viewController] - 1];
}

- (nullable UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController {
  return self[[self indexForViewController:viewController] + 1];
}

#pragma mark - Subscripting Support

- (AMPKWebViewerViewController *)objectAtIndexedSubscript:(NSInteger)index {
  if (index < 0 || index >= self.count) {
    return nil;
  }

  __block BOOL needsToResetContentOffset = YES;
  __block AMPKWebViewerViewController *ampWebViewController;
  [_viewControllers enumerateObjectsUsingBlock:
      ^(AMPKWebViewerViewController *viewController, BOOL *stop) {
        if (viewController.viewerDataSourceIndex == index) {
          *stop = YES;
          ampWebViewController = viewController;
          needsToResetContentOffset = NO;
        }
  }];

  if (!ampWebViewController) {
    ampWebViewController = [_reuseableViewControllerPool anyObject];
    if (ampWebViewController) {
      [_reuseableViewControllerPool removeObject:ampWebViewController];
    }
  }

  if (!ampWebViewController) {
    ampWebViewController = [[AMPKWebViewerViewController alloc] initWithDomainName:_domainName];
  }

  ampWebViewController.viewerDataSourceIndex = index;
  [_viewControllers addObject:ampWebViewController];
  [ampWebViewController loadAmpArticle:_ampArticles[index] withHeaders:_headers];

  if (_recordedContentOffset[@(index)] && needsToResetContentOffset) {
    ampWebViewController.viewerContentOffset = [_recordedContentOffset[@(index)] CGPointValue];
  }

  return ampWebViewController;
}

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  AMPKViewerDataSource *dataSource =
      [[[self class] alloc] initWithDomainName:_domainName];
  dataSource->_ampArticles = [_ampArticles copy];
  return dataSource;
}

#pragma mark - Debug

- (NSString *)description {
  return [NSString stringWithFormat:
              @"<%@: %p, ampURLs: %@, visible: %@, recycle: %@, recordOffset: %@.>",
              NSStringFromClass([self class]), self, _ampArticles, _viewControllers,
              _reuseableViewControllerPool, _recordedContentOffset];
}

@end

NS_ASSUME_NONNULL_END
