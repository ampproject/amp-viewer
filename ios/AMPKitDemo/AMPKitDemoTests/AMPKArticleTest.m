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

#import "AMPKArticle.h"

#import <XCTest/XCTest.h>

@interface AMPKArticleTest : XCTestCase
@end

@implementation AMPKArticleTest

- (void)testPublisherURLEqual {
  AMPKArticle *article1 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  AMPKArticle *article2 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  XCTAssertEqualObjects(article1, article2);
}

- (void)testPublisherURLNotEqual {
  AMPKArticle *article1 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  AMPKArticle *article2 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com/test"]];
  XCTAssertNotEqualObjects(article1, article2);
}

- (void)testCDNURLEqual {
  AMPKArticle *article1 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]
                           cdnURL:[NSURL URLWithString:@"http://www.test.com"]];
  AMPKArticle *article2 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]
                           cdnURL:[NSURL URLWithString:@"http://www.test.com"]];
  XCTAssertEqualObjects(article1, article2);
}

- (void)testCDNURLNotEqual {
  AMPKArticle *article1 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]
                           cdnURL:[NSURL URLWithString:@"http://www.test.com"]];
  AMPKArticle *article2 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]
                           cdnURL:[NSURL URLWithString:@"http://www.test.com/test"]];
  XCTAssertNotEqualObjects(article1, article2);
}

- (void)testCDNURLNil {
  AMPKArticle *article1 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]
                           cdnURL:[NSURL URLWithString:@"http://www.test.com"]];
  AMPKArticle *article2 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  XCTAssertNotEqualObjects(article1, article2);
}

- (void)testCanonicalURLEqual {
  AMPKArticle *article1 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  article1.canonicalURL = [NSURL URLWithString:@"http://cdn.ampproject.org"];
  AMPKArticle *article2 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  article2.canonicalURL = [NSURL URLWithString:@"http://cdn.ampproject.org"];
  XCTAssertEqualObjects(article1, article2);
}

- (void)testCanonicalURLNotEqual {
  AMPKArticle *article1 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  article1.canonicalURL = [NSURL URLWithString:@"http://cdn.ampproject.org"];
  AMPKArticle *article2 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  article2.canonicalURL = [NSURL URLWithString:@"http://cdn.ampproject.org/test"];
  XCTAssertNotEqualObjects(article1, article2);
}

- (void)testCanonicalURLNil {
  AMPKArticle *article1 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  article1.canonicalURL = [NSURL URLWithString:@"http://cdn.ampproject.org"];
  AMPKArticle *article2 =
      [AMPKArticle articleWithURL:[NSURL URLWithString:@"http://www.google.com"]];
  XCTAssertNotEqualObjects(article1, article2);
}

@end
