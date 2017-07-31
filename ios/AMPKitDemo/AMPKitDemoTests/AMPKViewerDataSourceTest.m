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

#import <XCTest/XCTest.h>

#import "AMPKArticle.h"
#import "AMPKArticleProtocol.h"
#import "AMPKWebViewerViewController.h"
#import "AMPKWebViewerViewController_private.h"

#import <OCMock/OCMock.h>

@interface AMPKViewerDataSourceTest : XCTestCase

@property(nonatomic) AMPKViewerDataSource *subject;
@property(nonatomic) id mockDelegate;
@property(nonatomic) NSURL *domainURL;
@end

@implementation AMPKViewerDataSourceTest

- (void)setUp {
  [super setUp];
  self.domainURL = [NSURL URLWithString:@"http://www.google.com"];
  self.subject = [[AMPKViewerDataSource alloc] initWithDomainName:self.domainURL];
  self.mockDelegate =
      OCMStrictProtocolMock(@protocol(AMPKViewerDataSourceDelegate));
}

/** Test for calling setAmpURLs: method. */
- (void)testSetAmpUrls {
  self.subject.delegate = self.mockDelegate;
  [[self.mockDelegate expect] ampViewerDataSourceDidChange:self.subject];

  [self.subject setAmpArticles:[self generateURLsWithCount:1] usingHeaders:nil];

  XCTAssertEqual(self.subject.count, 1, @"subject should contain only 1 AMP URL");
  [self.mockDelegate verify];
}

/** Test for changing existed AmpURL to a new one via setAmpURLs: method. */
- (void)testUpdateAmpUrls {
  [self.subject setAmpArticles:[self generateURLsWithCount:1] usingHeaders:nil];
  self.subject.delegate = self.mockDelegate;

  [[self.mockDelegate expect] ampViewerDataSourceDidChange:self.subject];

  [self.subject setAmpArticles:[self generateURLsWithCount:3] usingHeaders:nil];

  XCTAssertEqual(self.subject.count, 3, @"subject should contain 2 AMP URLs");
  [self.mockDelegate verify];
}

/** Test for AMP viewer would load the correct AMP url when using setAmpURLs: method. */
- (void)testAmpViewerController {
  NSArray<id<AMPKArticleProtocol>> *ampURLs = [self generateURLsWithCount:5];

  [self.subject setAmpArticles:ampURLs usingHeaders:nil];

  XCTAssertEqual(self.subject.count, ampURLs.count);
  for (NSInteger index = 0; index < ampURLs.count; index++) {
    XCTAssertEqualObjects(self.subject[index].article.publisherURL,
                          ampURLs[index].publisherURL,
                          @"AMP URL should be match");
  }
}

/** Test for querying the indexForViewController: method with valid result. */
- (void)testDataSourceIndexOfViewController {
  NSArray<id<AMPKArticleProtocol>> *ampURLs = [self generateURLsWithCount:10];

  [self.subject setAmpArticles:ampURLs usingHeaders:nil];

  AMPKWebViewerViewController *viewer = self.subject[5];

  XCTAssertEqual([self.subject indexForViewController:viewer], 5,
                 @"AMP viewer should be return correct.");
}

/** Test for querying the indexForViewController: method with invalid result. */
- (void)testDataSourceIndexOfViewControllerForNotFound {
  [self.subject setAmpArticles:[self generateURLsWithCount:1] usingHeaders:nil];

  UIViewController *viewer =
      [[AMPKWebViewerViewController alloc] initWithDomainName:self.domainURL];

  XCTAssertThrows([self.subject indexForViewController:viewer],
                  @"Expect -indexForViewController: to be assert for not found amp viewer");

  viewer = [[UIViewController alloc] initWithNibName:nil bundle:nil];
  XCTAssertThrows(
      [self.subject indexForViewController:viewer],
      @"Expect -indexForViewController: to be assert for incorrect viewController class");
}

/**
 * Test for UIPagingDateSource implementation of
 * pageViewController:viewControllerAfterViewController: method with a valid result.
 */
- (void)testPageViewDataSourceDelegateHasAfter {
  UIPageViewController *pageViewController = [[UIPageViewController alloc] init];
  NSArray<id<AMPKArticleProtocol>> *ampURLs = [self generateURLsWithCount:5];
  [self.subject setAmpArticles:ampURLs usingHeaders:nil];

  UIViewController *viewer = self.subject[3];
  AMPKWebViewerViewController *afterViewer = (AMPKWebViewerViewController *)
      [self.subject pageViewController:pageViewController viewControllerAfterViewController:viewer];

  XCTAssertNotNil(afterViewer);
  XCTAssertEqualObjects(afterViewer.article.publisherURL, ampURLs[4].publisherURL);
  XCTAssertEqual([self.subject indexForViewController:afterViewer], 4);
}

/**
 * Test for UIPagingDateSource implementation of
 * pageViewController:viewControllerAfterViewController: method with an invalid result.
 */
- (void)testPageViewDataSourceDelegateHasNotAfter {
  UIPageViewController *pageViewController = [[UIPageViewController alloc] init];
  [self.subject setAmpArticles:[self generateURLsWithCount:5] usingHeaders:nil];

  XCTAssertNil([self.subject pageViewController:pageViewController
              viewControllerAfterViewController:self.subject[4]]);
}

/**
 * Test for UIPagingDateSource implementation of
 * pageViewController:viewControllerBeforeViewController: method with a valid result.
 */
- (void)testPageViewDataSourceDelegateHasBefore {
  UIPageViewController *pageViewController = [[UIPageViewController alloc] init];
  NSArray<id<AMPKArticleProtocol>> *ampURLs = [self generateURLsWithCount:5];
  [self.subject setAmpArticles:ampURLs usingHeaders:nil];

  UIViewController *viewer = self.subject[3];
  AMPKWebViewerViewController *beforeViewer =
      (AMPKWebViewerViewController *)[self.subject pageViewController:pageViewController
                                 viewControllerBeforeViewController:viewer];

  XCTAssertNotNil(beforeViewer);
  XCTAssertEqualObjects(beforeViewer.article.publisherURL, ampURLs[2].publisherURL);
  XCTAssertEqual([self.subject indexForViewController:beforeViewer], 2);
}

/**
 * Test for UIPagingDateSource implementation of
 * pageViewController:viewControllerBeforeViewController: method with an invalid result.
 */
- (void)testPageViewDataSourceDelegateHasNotBefore {
  UIPageViewController *pageViewController = [[UIPageViewController alloc] init];
  [self.subject setAmpArticles:[self generateURLsWithCount:5] usingHeaders:nil];

  XCTAssertNil([self.subject pageViewController:pageViewController
              viewControllerBeforeViewController:self.subject[0]]);
}

/** Test for adopting NSCoding protocol. */
- (void)testCodingProtocol {
  [self.subject setAmpArticles:[self generateURLsWithCount:5] usingHeaders:nil];

  NSData *subjectData = [NSKeyedArchiver archivedDataWithRootObject:self.subject];
  AMPKViewerDataSource *unarchiveredDataSource =
      [NSKeyedUnarchiver unarchiveObjectWithData:subjectData];

  XCTAssertEqual(unarchiveredDataSource.count, self.subject.count);
  for (NSInteger index = 0; index < self.subject.count; index ++) {
    XCTAssertEqualObjects(unarchiveredDataSource[index].webURL, self.subject[index].webURL);
  }
}

/** Test for AmpViewerController has been recycled by the dataSource. */
- (void)testAmpViewerControllerDidRecycle {
  [self.subject setAmpArticles:[self generateURLsWithCount:10] usingHeaders:nil];

  UIViewController *recycle = self.subject[0];

  [self.subject setCurrentVisibleIndex:5];

  XCTAssertThrows([self.subject indexForViewController:recycle]);
}

/** Test for AmpViewerController has not been recycled by the dataSource. */
- (void)testAmpViewerControllerWillNotRecycle {
  [self.subject setAmpArticles:[self generateURLsWithCount:10] usingHeaders:nil];

  AMPKWebViewerViewController *before = self.subject[3];
  AMPKWebViewerViewController *after = self.subject[5];

  [self.subject setCurrentVisibleIndex:4];

  XCTAssertNoThrow([self.subject indexForViewController:before]);
  XCTAssertNoThrow([self.subject indexForViewController:after]);
}

/** Test that AmpViewerController properly handles prefetching. */
- (void)testAmpViewerPrefetch {
  [self.subject setAmpArticles:[self generateURLsWithCount:10] usingHeaders:nil];

  [self.subject setCurrentVisibleIndex:4];
  XCTAssertEqual([self.subject allLoadedViewControllers].count, 3);
  [self.subject prefetchItemAtIndex:5];
  XCTAssertEqual([self.subject allLoadedViewControllers].count, 4);
  [self.subject setCurrentVisibleIndex:5];
  XCTAssertEqual([self.subject allLoadedViewControllers].count, 3);
}

/** Test for AmpViewerController has been reused by the dataSource. */
- (void)testAmpViewerControllerReuse {
  CGPoint originalOffset = CGPointMake(100, 100);
  NSArray<id<AMPKArticleProtocol>> *ampURLs = [self generateURLsWithCount:10];
  [self.subject setAmpArticles:ampURLs usingHeaders:nil];

  [self.subject setCurrentVisibleIndex:5];
  AMPKWebViewerViewController *viewer = self.subject[6];
  [self modifyScrollView:viewer.webScrollView forOffset:originalOffset];

  [self.subject setCurrentVisibleIndex:4];

  // make sure viewer has been recycle
  XCTAssertNotEqual(viewer.viewerDataSourceIndex, 6);

  [self.subject setCurrentVisibleIndex:5];
  viewer = self.subject[6];

  XCTAssertTrue(CGPointEqualToPoint(viewer.initialContentOffset, originalOffset));
}

/** Test to make sure two different arrays with the same objects return true. */
- (void)testAmpArticleEqualCheck {
  NSArray<id<AMPKArticleProtocol>> *ampURLs = [self generateURLsWithCount:5];
  [self.subject setAmpArticles:ampURLs usingHeaders:nil];

  XCTAssertTrue([self.subject areArticlesSimilar:ampURLs]);
}

/** Test to make sure articles are equal if their CDN addresses are equal. */
- (void)testAmpArticleEqualCheckWithCDN {
  NSArray<id<AMPKArticleProtocol>> *ampURLs = [self generateURLsWithCount:5];
  for (id<AMPKArticleProtocol> article in ampURLs) {
    NSString *URLString =
        [NSString stringWithFormat:@"http://testing.com/%@", article.publisherURL.absoluteString];
    article.cdnURL = [NSURL URLWithString:URLString];
  }
  NSArray<id<AMPKArticleProtocol>> *ampURLCopy =
      [[NSArray alloc] initWithArray:ampURLs copyItems:YES];
  [self.subject setAmpArticles:ampURLs usingHeaders:nil];

  XCTAssertTrue([self.subject areArticlesSimilar:ampURLCopy]);
}

/** Test to make sure articles are not equal if the CDN is not equal. */
- (void)testAmpArticleNotEqualCheckWithBadCDN {
  NSArray<id<AMPKArticleProtocol>> *ampURLs = [self generateURLsWithCount:5];
  NSArray<id<AMPKArticleProtocol>> *ampURLCopy =
      [[NSArray alloc] initWithArray:ampURLs copyItems:YES];
  [self.subject setAmpArticles:ampURLs usingHeaders:nil];

  for (id<AMPKArticleProtocol> article in ampURLCopy) {
    article.cdnURL = [NSURL URLWithString:@"http://wrong.com"];
  }

  XCTAssertFalse([self.subject areArticlesSimilar:ampURLCopy]);
}

/** Test to make sure arrays of different sizes return false. */
- (void)testAmpArticleOfVaryingSizeNotEqualCheck {
  NSArray<id<AMPKArticleProtocol>> *ampURLs = [self generateURLsWithCount:5];
  [self.subject setAmpArticles:ampURLs usingHeaders:nil];

  XCTAssertFalse([self.subject areArticlesSimilar:[self generateURLsWithCount:3]]);
}

/** Test to make sure if at least one article is different returns false. */
- (void)testAmpArticleNotEqualCheck {
  NSArray<id<AMPKArticleProtocol>> *ampURLs = [self generateURLsWithCount:5];
  [self.subject setAmpArticles:ampURLs usingHeaders:nil];
  NSArray<id<AMPKArticleProtocol>> *ampURLCopy =
      [[NSArray alloc] initWithArray:ampURLs copyItems:YES];
  ampURLCopy[4].publisherURL = [NSURL URLWithString:@"www.nope.com"];

  XCTAssertFalse([self.subject areArticlesSimilar:ampURLCopy]);
}

#pragma mark - Private

- (NSArray<id<AMPKArticleProtocol>> *)generateURLsWithCount:(NSInteger)count {
  NSMutableArray<id<AMPKArticleProtocol>> *articles = [NSMutableArray arrayWithCapacity:count];
  for (NSUInteger indx = 0; indx < count; indx++) {
    NSString *urlString = [NSString stringWithFormat:@"https://www.google.com/%@", @(indx)];
    AMPKArticle *article = [[AMPKArticle alloc] init];
    article.publisherURL = [NSURL URLWithString:urlString];
    [articles addObject:article];
  }
  return articles;
}

- (void)modifyScrollView:(UIScrollView *)scrollView forOffset:(CGPoint)offset {
  scrollView.contentSize = CGSizeMake(offset.x * 2, offset.y * 2);
  scrollView.contentOffset = offset;
}

@end
