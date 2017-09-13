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

#import "AMPKTestHelper.h"

#import "AMPKArticle.h"
#import "AMPKWebViewerJsMessage.h"
#import "AMPKWebViewerJsMessage_private.h"
#import "AMPKWebViewerViewController.h"

#import <OCMock/OCMock.h>

NSString *const kAmpKitTestSourceHostName = @"https://cdn.ampproject.org";
static NSString *const kTestBroadcastMessageURLString = @"http://www.nope.com";

@implementation AMPKTestHelper

+ (id)mockWKScriptMessageForType:(AMPKMessageType)type
                            name:(NSString *)name
                       channelID:(NSInteger)channelID
                       requestID:(NSInteger)requestID
                            RSVP:(BOOL)rsvp
                            data:(id)data
                           error:(NSString *)error {
  id jsMessageMock = OCMPartialMock([[WKScriptMessage alloc] init]);

  id wkFrameInfoMock = OCMStrictClassMock([WKFrameInfo class]);
  id nsUrlRequestMock = OCMStrictClassMock([NSURLRequest class]);
  [[[nsUrlRequestMock stub] andReturn:[NSURL URLWithString:kAmpKitTestSourceHostName]] URL];
  [[[wkFrameInfoMock stub] andReturn:nsUrlRequestMock] request];

  NSMutableDictionary *scriptData =
      [@{@"app" : @"__AMPHTML__",
         @"type" : [AMPKWebViewerJsMessage stringForMessageType:type],
         @"name" : name,
         @"channelid" : @(channelID),
         @"requestid" : @(requestID),
         @"rsvp" : @(rsvp)}
       mutableCopy];

  if (data) {
    scriptData[@"data"] = data;
  }
  if (error) {
    scriptData[@"error"] = error;
  }

  [[[jsMessageMock stub] andReturn:scriptData] body];

  [[[jsMessageMock stub] andReturn:wkFrameInfoMock] frameInfo];

  return jsMessageMock;
}

+ (AMPKWebViewerViewController *)setupWebViewerViewController {
  NSURL *domainURL = [NSURL URLWithString:@"http://www.google.com"];
  AMPKWebViewerViewController *ampViewer =
      [[AMPKWebViewerViewController alloc] initWithDomainName:domainURL];
  UIView *view = ampViewer.view;
  ((void) view);
  return ampViewer;
}

+ (id)mockViewer {
  return [self mockViewerWithURL:[self testURL]];
}

+ (id)mockViewerWithURL:(NSURL *)url {
  id articleMock = OCMStrictClassMock([AMPKArticle class]);
  [[[articleMock stub] andReturn:url] publisherURL];
  id viewerMock = OCMClassMock([AMPKWebViewerViewController class]);
  [[[viewerMock stub] andReturn:articleMock] article];

  return viewerMock;
}

+ (NSURL *)testURL {
  return [NSURL URLWithString:kTestBroadcastMessageURLString];
}

@end

@implementation AMPKTestArticle

@synthesize cdnURL = _cdnURL;
@synthesize publisherURL = _publisherURL;
@synthesize canonicalURL = _canonicalURL;

+ (instancetype)articleWithURL:(NSURL *)articleURL cdnURL:(NSURL *)cdnURL {
  AMPKTestArticle *article = [[AMPKTestArticle alloc] init];
  article.publisherURL = articleURL;
  article.cdnURL = cdnURL;
  return article;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:self.cdnURL forKey:@"_cdn"];
  [aCoder encodeObject:self.publisherURL forKey:@"_publishers"];
  [aCoder encodeObject:self.canonicalURL forKey:@"_canonical"];
}

- (instancetype)copyWithZone:(NSZone *)zone {
  AMPKTestArticle *copy = [[AMPKTestArticle alloc] init];
  copy.cdnURL = self.cdnURL;
  copy.publisherURL = self.publisherURL;
  copy.canonicalURL = self.canonicalURL;
  return copy;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  if (self) {
    _cdnURL = [aDecoder decodeObjectForKey:@"_cdn"];
    _publisherURL = [aDecoder decodeObjectForKey:@"_publishers"];
    _canonicalURL = [aDecoder decodeObjectForKey:@"_canonical"];
  }
  return self;
}

@end
