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

#import <XCTest/XCTest.h>

#import "AMPKArticle.h"
#import "AMPKViewer.h"
#import "AMPKViewerDataSource.h"
#import "AMPKWebViewerViewController.h"
#import "AMPKTestHelper.h"

#import <OCMock/OCMock.h>

NS_ASSUME_NONNULL_BEGIN

@interface AMPKPrefetchControllerTest : XCTestCase
@property(nonatomic) AMPKPrefetchController *subject;
@end

@implementation AMPKPrefetchControllerTest

- (void)setUp {
  [super setUp];
  self.subject = [[AMPKPrefetchController alloc] init];
}

- (void)testValidAMPArticles {
  NSArray <AMPKArticle *> *validArticles =
      @[[AMPKArticle articleWithURL:[NSURL URLWithString:@"https://www.google.com/test"]]];
  [self.subject ampViewerWithArticles:validArticles usingHeaders:nil prefetchedAtIndex:0];
  XCTAssertEqual(self.subject.ampViewController.viewerDataSource.count, 1);
}

- (void)testInvalidHostAMPArticles {
  NSArray <AMPKArticle *> *validArticles =
      @[[AMPKArticle articleWithURL:[NSURL URLWithString:@"www.google.com/test"]]];
  [self.subject ampViewerWithArticles:validArticles usingHeaders:nil prefetchedAtIndex:0];
  XCTAssertEqual(self.subject.ampViewController.viewerDataSource.count, 0);
}

- (void)testInvalidCDNURL {
  NSArray <id<AMPKArticleProtocol>> *validArticles =
  @[[AMPKTestArticle articleWithURL:[NSURL URLWithString:@"https://www.google.com/test"]
                             cdnURL:[NSURL URLWithString:@""]]];
  [self.subject ampViewerWithArticles:validArticles usingHeaders:nil prefetchedAtIndex:0];
  XCTAssertEqual(self.subject.ampViewController.viewerDataSource.count, 0);
}

- (void)testValidCDNURL {
  NSArray <AMPKArticle *> *validArticles =
  @[[AMPKArticle articleWithURL:[NSURL URLWithString:@"https://www.google.com/test"]
                         cdnURL:[NSURL URLWithString:@"https://google.cdn.ampproject.org"]]];
  [self.subject ampViewerWithArticles:validArticles usingHeaders:nil prefetchedAtIndex:0];
  XCTAssertEqual(self.subject.ampViewController.viewerDataSource.count, 1);
}

- (void)testInvalidAMPArticles {
  NSArray <AMPKArticle *> *invalidArticles =
      @[[AMPKArticle articleWithURL:[NSURL URLWithString:@""]]];
  [self.subject ampViewerWithArticles:invalidArticles usingHeaders:nil prefetchedAtIndex:0];
  XCTAssertEqual(self.subject.ampViewController.viewerDataSource.count, 0);
}

- (void)testValidInvalidAMPArticles {
  NSArray <AMPKArticle *> *allArticles =
      @[
        [AMPKArticle articleWithURL:[NSURL URLWithString:@""]],
        [AMPKArticle articleWithURL:[NSURL URLWithString:@"https://www.google.com/test"]]
      ];
  [self.subject ampViewerWithArticles:allArticles usingHeaders:nil prefetchedAtIndex:0];
  XCTAssertEqual(self.subject.ampViewController.viewerDataSource.count, 1);
}

- (void)testMultipleValidArticles {
  NSArray <AMPKArticle *> *validArticles =
      @[
        [AMPKArticle articleWithURL:[NSURL URLWithString:@"https://www.google.com/test"]],
        [AMPKArticle articleWithURL:[NSURL URLWithString:@"https://www.test.com/test"]]
      ];
  [self.subject ampViewerWithArticles:validArticles usingHeaders:nil prefetchedAtIndex:0];
  XCTAssertEqual(self.subject.ampViewController.viewerDataSource.count, 2);
}

- (void)testChangingPrefetch {
  NSArray <AMPKArticle *> *validArticles =
      @[
        [AMPKArticle articleWithURL:[NSURL URLWithString:@"https://www.google.com/test"]],
        [AMPKArticle articleWithURL:[NSURL URLWithString:@"https://www.test.com/test"]]
      ];
  [self.subject ampViewerWithArticles:validArticles usingHeaders:nil prefetchedAtIndex:0];
  XCTAssertEqualObjects(self.subject.ampViewController.currentAmpWebViewerController.article,
                        validArticles[0]);
  [self.subject updatePrefetchIndex:1];
  XCTAssertEqualObjects(self.subject.ampViewController.currentAmpWebViewerController.article,
                        validArticles[1]);
}

- (void)testDataSourceProtocolMethod {
  id protocolMock = OCMProtocolMock(@protocol(AMPKPrefetchProvider));
  OCMStub([protocolMock defaultDataSource]).andReturn([NSObject new]);
  self.subject.prefetchProvider = protocolMock;
  NSArray <AMPKArticle *> *validArticles =
      @[[AMPKArticle articleWithURL:[NSURL URLWithString:@"https://www.google.com/test"]]];
  [self.subject ampViewerWithArticles:validArticles usingHeaders:nil prefetchedAtIndex:0];
  OCMVerify([protocolMock defaultDataSource]);
  [protocolMock stopMocking];
}

- (void)testViewerProtocolMethod {
  id protocolMock = OCMProtocolMock(@protocol(AMPKPrefetchProvider));
  NSURL *defaultURL = [NSURL URLWithString:@"https://www.google.com"];
  AMPKViewerDataSource *viewerDataSource =
      [[AMPKViewerDataSource alloc] initWithDomainName:defaultURL];
  id viewerMock = OCMPartialMock([[AMPKViewer alloc] initWithViewerDataSource:viewerDataSource]);
  OCMStub([protocolMock newViewerWithDataSource:[OCMArg any]]).andReturn(viewerMock);
  OCMStub([protocolMock defaultDataSource]).andReturn(viewerDataSource);
  self.subject.prefetchProvider = protocolMock;
  NSArray <AMPKArticle *> *validArticles =
      @[[AMPKArticle articleWithURL:[NSURL URLWithString:@"https://www.google.com/test"]]];
  [self.subject ampViewerWithArticles:validArticles usingHeaders:nil prefetchedAtIndex:0];
  OCMVerify([protocolMock newViewerWithDataSource:[OCMArg any]]);
  [protocolMock stopMocking];
}

- (void)testAbandonPrefetchedViewer {
  NSArray <AMPKArticle *> *validArticles =
      @[[AMPKArticle articleWithURL:[NSURL URLWithString:@"https://www.google.com/test"]]];
  [self.subject ampViewerWithArticles:validArticles usingHeaders:nil prefetchedAtIndex:0];

  AMPKViewer *currentViewer = self.subject.ampViewController;
  [self.subject abandonPrefetchedViewer];

  XCTAssertNotEqual(self.subject.ampViewController, currentViewer);
}

@end

NS_ASSUME_NONNULL_END
