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

#import "NSURL+AMPK.h"

#import "GTMDefines.h"

NS_ASSUME_NONNULL_BEGIN

@implementation AMPKArticle

+ (instancetype)articleWithURL:(NSURL *)url {
  return [AMPKArticle articleWithURL:url cdnURL:nil];
}

+ (instancetype)articleWithURL:(NSURL *)url cdnURL:(nullable NSURL *)cdnURL {
  AMPKArticle *article = [[AMPKArticle alloc] init];
  article.publisherURL = url;
  article.cdnURL = cdnURL;
  return article;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:_cdnURL forKey:GTM_SEL_STRING(cdnURL)];
  [aCoder encodeObject:_publisherURL forKey:GTM_SEL_STRING(publisherURL)];
  [aCoder encodeObject:_canonicalURL forKey:GTM_SEL_STRING(canonicalURL)];
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  if (self) {
    _cdnURL = [aDecoder decodeObjectForKey:GTM_SEL_STRING(cdnURL)];
    _publisherURL = [aDecoder decodeObjectForKey:GTM_SEL_STRING(publisherURL)];
    _canonicalURL = [aDecoder decodeObjectForKey:GTM_SEL_STRING(canonicalURL)];
  }

  return self;
}

- (instancetype)copyWithZone:(nullable NSZone *)zone {
  AMPKArticle *ampArticle = [[[self class] alloc] init];
  ampArticle.publisherURL = [_publisherURL copy];
  ampArticle.cdnURL = [_cdnURL copy];
  ampArticle.canonicalURL = [_canonicalURL copy];
  return ampArticle;
}

- (BOOL)isEqual:(id)object {
  if (object == self) {
    return YES;
  }
  if (![object isKindOfClass:[AMPKArticle class]]) {
    return NO;
  }

  AMPKArticle *otherArticle = (AMPKArticle *)object;
  BOOL equalPublisherURL =
      self.publisherURL && [self.publisherURL isEqual:otherArticle.publisherURL];
  BOOL equalCDNURL =
      self.cdnURL == nil ? otherArticle.cdnURL == nil : [self.cdnURL isEqual:otherArticle.cdnURL];
  BOOL equalCanonicalURL = self.canonicalURL == nil ?
      otherArticle.canonicalURL == nil : [self.canonicalURL isEqual:otherArticle.canonicalURL];
  return equalPublisherURL && equalCDNURL && equalCanonicalURL;
}

- (NSString *)description {
  return [NSString stringWithFormat:
              @"<%@: %p, url: %@, cdn: %@, canonical: %@>",
              NSStringFromClass([self class]),
              self,
              self.publisherURL,
              self.cdnURL,
              self.canonicalURL];
}

@end

NS_ASSUME_NONNULL_END
