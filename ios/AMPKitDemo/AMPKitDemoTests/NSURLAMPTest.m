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

#import "NSURL+AMPK.h"

#import <XCTest/XCTest.h>

static NSString *kDomainName = @"https://www.google.com";

@interface NSURLAMPTest : XCTestCase
@end

@implementation NSURLAMPTest

- (void)testProxySecureURLGeneration {
  NSString *originalURL = @"https://www.example.com/article.html?page=1#test=1";
  NSString *expectedURL =
      @"https://cdn.ampproject.org/c/s/www.example.com/article.html?page=1#test=1";
  NSURL *url = [NSURL URLWithString:originalURL];

  XCTAssertEqualObjects([[url ampk_ProxiedURL] absoluteString], expectedURL);
}

- (void)testProxyInsecureURLGeneration {
  NSString *originalURL = @"http://www.example.com/article.html?page=1#test=1";
  NSString *expectedURL =
      @"https://cdn.ampproject.org/c/www.example.com/article.html?page=1#test=1";
  NSURL *url = [NSURL URLWithString:originalURL];

  XCTAssertEqualObjects([[url ampk_ProxiedURL] absoluteString], expectedURL);
}

- (void)testGeneratingSecureSharingURL {
  NSString *originalURL = @"https://www.example.com/article.html?page=1#test=1";
  NSURL *url = [NSURL URLWithString:originalURL];
  NSString *expectedPath =
      @"https%3A%2F%2Fwww.google.com%2Famp%2Fs%2Fwww.example.com%2Farticle.html%3Fpage=1%23test=1";

  NSURL *sharingURL =
      [url URLBySettingProxyHashFragmentsForDomain:[NSURL URLWithString:kDomainName]];
  XCTAssert([[sharingURL absoluteString] hasSuffix:expectedPath],
            @"expected path suffix: %@\n actual URL: %@", expectedPath, sharingURL.absoluteString);
}

- (void)testGeneratingInsecureSharingURL {
  NSString *originalURL = @"http://www.example.com/article.html";
  NSURL *url = [NSURL URLWithString:originalURL];
  NSString *expectedPath = @"https%3A%2F%2Fwww.google.com%2Famp%2Fwww.example.com%2Farticle.html";

  NSURL *sharingURL =
      [url URLBySettingProxyHashFragmentsForDomain:[NSURL URLWithString:kDomainName]];
  XCTAssert([[sharingURL absoluteString] hasSuffix:expectedPath],
            @"expected path suffix: %@\n actual URL: %@", expectedPath, sharingURL.absoluteString);
}

- (void)testEncodingSharingURLWithPort {
  NSString *originalURL = @"http://www.example.com:5050/article.html?page=1#test=1";
  NSURL *url = [NSURL URLWithString:originalURL];
  NSString *expectedPath = @"%2Famp%2Fwww.example.com%3A5050%2Farticle.html%3Fpage=1%23test=1";

  NSURL *sharingURL =
      [url URLBySettingProxyHashFragmentsForDomain:[NSURL URLWithString:kDomainName]];
  XCTAssert([[sharingURL absoluteString] hasSuffix:expectedPath],
            @"expected path suffix: %@\n actual URL: %@", expectedPath, sharingURL.absoluteString);
}

- (void)testEncodingSharingURLWithBadAMPDomain {
  NSString *originalURL = @"http://www.example.com:5050/article.html?page=1#test=1";
  NSURL *badAMPDomain = [NSURL URLWithString:@"www.google.com"];
  NSURL *url = [NSURL URLWithString:originalURL];

  XCTAssertThrows([url URLBySettingProxyHashFragmentsForDomain:badAMPDomain]);
}

- (void)testDoesNotAddExtra {
  NSURL *url = [NSURL URLWithString:@"http://www.test.com/"];

  XCTAssert([[url ampPath] isEqualToString:@"/"]);
}

- (void)testPathEqualsWhenNoPathWithTrailing {
  NSURL *url = [NSURL URLWithString:@"http://www.test.com/"];

  XCTAssert([[url ampPath] isEqualToString:url.path]);
}

- (void)testDoesNotAddMissingSlash {
  NSURL *url = [NSURL URLWithString:@"http://www.test.com"];

  XCTAssert([[url ampPath] isEqualToString:@""]);
}

- (void)testAddingMissingSlashWithOtherPath {
  NSURL *url = [NSURL URLWithString:@"http://www.test.com/my-article/"];

  XCTAssert([[url ampPath] isEqualToString:@"/my-article/"]);
}

- (void)testDoesNotAddSlashWithOtherPath {
  NSURL *url = [NSURL URLWithString:@"http://www.test.com/my-article"];

  XCTAssert([[url ampPath] isEqualToString:@"/my-article"]);
}

- (void)testDoesNotAddSlashEqualsNormalPath {
  NSURL *url = [NSURL URLWithString:@"http://www.test.com/my-article"];

  XCTAssert([[url ampPath] isEqualToString:url.path]);
}

- (void)testDoesNotAddSlashDoesNotEqualNormalPath {
  NSURL *url = [NSURL URLWithString:@"http://www.test.com/my-article/"];

  XCTAssertFalse([[url ampPath] isEqualToString:url.path]);
}

- (void)testRealURLTrailingSlashProxyAddress {
  NSURL *url = [NSURL URLWithString:@"http://www.test.com/sites/"];
  NSString *cdnString = @"https://cdn.ampproject.org/c/www.test.com/sites/";
  XCTAssert([[url ampk_ProxiedURL].absoluteString isEqualToString:cdnString]);
}

- (void)testCDNMatchesForCURLS {
  NSString *url = @"https://www-theverge-com.cdn.ampproject.org/c/s/www.theverge.com/platform/amp/2016/4/25/11501484/what-in-the-world-is-obama-looking-at-in-virtual-reality";
  NSURL *CURLSCDN = [NSURL URLWithString:url];
  XCTAssertTrue([CURLSCDN matchesCDNURL:CURLSCDN]);
}

- (void)testCDNMatchesForNonCURLS {
  NSString *url = @"https://cdn.ampproject.org/c/s/www.theverge.com/platform/amp/2016/4/25/11501484/what-in-the-world-is-obama-looking-at-in-virtual-reality";
  NSURL *nonCURLSCDN = [NSURL URLWithString:url];
  XCTAssertTrue([nonCURLSCDN matchesCDNURL:nonCURLSCDN]);
}

- (void)testCDNNonCURLSMatchesCURLS {
  NSString *CURLSURL = @"https://www-theverge-com.cdn.ampproject.org/c/s/www.theverge.com/platform/amp/2016/4/25/11501484/what-in-the-world-is-obama-looking-at-in-virtual-reality";
  NSString *nonCURLSURL = @"https://cdn.ampproject.org/c/s/www.theverge.com/platform/amp/2016/4/25/11501484/what-in-the-world-is-obama-looking-at-in-virtual-reality";
  NSURL *CURLSCDN = [NSURL URLWithString:CURLSURL];
  NSURL *nonCURLSCDN = [NSURL URLWithString:nonCURLSURL];
  XCTAssertTrue([nonCURLSCDN matchesCDNURL:CURLSCDN]);
}

- (void)testCDNCURLSMatchesNonCURLS {
  NSString *CURLSURL = @"https://www-theverge-com.cdn.ampproject.org/c/s/www.theverge.com/platform/amp/2016/4/25/11501484/what-in-the-world-is-obama-looking-at-in-virtual-reality";
  NSString *nonCURLSURL = @"https://cdn.ampproject.org/c/s/www.theverge.com/platform/amp/2016/4/25/11501484/what-in-the-world-is-obama-looking-at-in-virtual-reality";
  NSURL *CURLSCDN = [NSURL URLWithString:CURLSURL];
  NSURL *nonCURLSCDN = [NSURL URLWithString:nonCURLSURL];
  XCTAssertTrue([CURLSCDN matchesCDNURL:nonCURLSCDN]);
}

- (void)testNilForNonCDNURLSanitization {
  NSURL *URL = [NSURL URLWithString:@"http://www.google.com"];
  XCTAssertNil([URL sanitizedCDNURL]);
}

- (void)testNilForBaseCDNURLSanitization {
  NSURL *URL = [NSURL URLWithString:@"http://cdn.ampproject.org"];
  XCTAssertNil([URL sanitizedCDNURL]);
}

- (void)testNilForInvalidNumberOfPathsComponentsOnCDNURLSanitization {
  NSURL *URL = [NSURL URLWithString:@"http://cdn.ampproject.org/dogs"];
  XCTAssertNil([URL sanitizedCDNURL]);
}

- (void)testNilForNonArticleOnCDNURLSanitization {
  NSURL *URL = [NSURL URLWithString:@"http://cdn.ampproject.org/two/three/four"];
  XCTAssertNil([URL sanitizedCDNURL]);
}

- (void)testCDNDoesNotAlterSanitizedCDNURL {
  NSString *CURLSURL = @"https://www-theverge-com.cdn.ampproject.org/c/s/www.theverge.com/platform/amp/2016/4/25/11501484/what-in-the-world-is-obama-looking-at-in-virtual-reality";
  NSURL *URL = [NSURL URLWithString:CURLSURL];
  XCTAssertEqualObjects(URL, [URL sanitizedCDNURL]);
}

- (void)testDoesNotAlterSecurityStatusCDNURL {
  NSString *invalidCURLSURL = @"https://www-theverge-com.cdn.ampproject.org/c/s/www.theverge.com/platform/amp/2016/4/25/11501484/what-in-the-world-is-obama-looking-at-in-virtual-reality#test=1&visibilityState=prerender";
  NSURL *invalidCURLSURLURL = [NSURL URLWithString:invalidCURLSURL];
  NSString *CURLSURL = @"https://www-theverge-com.cdn.ampproject.org/c/s/www.theverge.com/platform/amp/2016/4/25/11501484/what-in-the-world-is-obama-looking-at-in-virtual-reality";
  NSURL *validCDNURL = [NSURL URLWithString:CURLSURL];
  XCTAssertEqualObjects(validCDNURL, [invalidCURLSURLURL sanitizedCDNURL]);
}

- (void)testSanitizesURLWithInSecureCDNURL {
  NSString *invalidCDN = @"https://www-theverge-com.cdn.ampproject.org/v/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event?amp_js_v=0.1#test=1&visibilityState=prerender";
  NSString *sanitizedCDN = @"https://www-theverge-com.cdn.ampproject.org/c/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event";

  NSURL *invalidCDNURL = [NSURL URLWithString:invalidCDN];
  NSURL *sanitizedCDNURL = [NSURL URLWithString:sanitizedCDN];
  XCTAssertEqualObjects(sanitizedCDNURL, [invalidCDNURL sanitizedCDNURL]);
}

- (void)testSanitizesURLWithSecureCDNURL {
  NSString *invalidCDN = @"https://www-theverge-com.cdn.ampproject.org/v/s/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event?amp_js_v=0.1#test=1&visibilityState=prerender";
  NSString *sanitizedCDN = @"https://www-theverge-com.cdn.ampproject.org/c/s/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event";

  NSURL *invalidCDNURL = [NSURL URLWithString:invalidCDN];
  NSURL *sanitizedCDNURL = [NSURL URLWithString:sanitizedCDN];
  XCTAssertEqualObjects(sanitizedCDNURL, [invalidCDNURL sanitizedCDNURL]);
}

- (void)testSanitizesNonCURLSURL {
  NSString *invalidCDN = @"https://cdn.ampproject.org/v/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event?amp_js_v=0.1#test=1&visibilityState=prerender";
  NSString *sanitizedCDN = @"https://cdn.ampproject.org/c/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event";

  NSURL *invalidCDNURL = [NSURL URLWithString:invalidCDN];
  NSURL *sanitizedCDNURL = [NSURL URLWithString:sanitizedCDN];
  XCTAssertEqualObjects(sanitizedCDNURL, [invalidCDNURL sanitizedCDNURL]);
}

- (void)testSanitizesURLWithTrailingSlash {
  NSString *invalidCDN = @"https://www-theverge-com.cdn.ampproject.org/v/s/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event/?amp_js_v=0.1#test=1&visibilityState=prerender";
  NSString *sanitizedCDN = @"https://www-theverge-com.cdn.ampproject.org/c/s/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event/";

  NSURL *invalidCDNURL = [NSURL URLWithString:invalidCDN];
  NSURL *sanitizedCDNURL = [NSURL URLWithString:sanitizedCDN];
  XCTAssertEqualObjects(sanitizedCDNURL, [invalidCDNURL sanitizedCDNURL]);
}

- (void)testCDNURLWithParams {
  NSString *inputCDNURLString = @"https://cdn.ampproject.org/c/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event/?usqp%3Dmq331AQECAAYAA%253D%253D";

  NSURL *inputCDNURL = [NSURL URLWithString:inputCDNURLString];
  NSURL *outputCDNURL = [inputCDNURL sanitizedCDNURL];
  XCTAssertEqualObjects(inputCDNURLString, outputCDNURL.absoluteString);
}

- (void)testCDNURLWithMultipleParams {
  NSString *inputCDNURLString = @"https://cdn.ampproject.org/c/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event/?test=yes&visibilityState=test&hello=world";
  NSString *expectedCDNURLString = @"https://cdn.ampproject.org/c/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event/?test=yes&hello=world";

  NSURL *inputCDNURL = [NSURL URLWithString:inputCDNURLString];
  NSURL *outputCDNURL = [inputCDNURL sanitizedCDNURL];
  XCTAssertEqualObjects(expectedCDNURLString, outputCDNURL.absoluteString);
}

- (void)testCDNURLWithBlacklistedParamFirst {
  NSString *inputCDNURLString = @"https://cdn.ampproject.org/c/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event/?visibilityState=test&test=yes&hello=world";
  NSString *expectedCDNURLString = @"https://cdn.ampproject.org/c/www.theverge.com/platform/amp/circuitbreaker/2017/9/6/16254802/new-iphone-change-event/?test=yes&hello=world";

  NSURL *inputCDNURL = [NSURL URLWithString:inputCDNURLString];
  NSURL *outputCDNURL = [inputCDNURL sanitizedCDNURL];
  XCTAssertEqualObjects(expectedCDNURLString, outputCDNURL.absoluteString);
}

@end
