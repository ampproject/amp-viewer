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

#import "AMPKArticleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

BOOL AMPKViewerShouldConsiderArticlesTheSame(id<AMPKArticleProtocol> article1,
                                             id<AMPKArticleProtocol> article2) {
  return (((article1.cdnURL == article2.cdnURL) || [article1.cdnURL isEqual:article2.cdnURL]) &&
          [article1.publisherURL isEqual:article2.publisherURL]);
}

BOOL AMPKArticleIsValid(id<AMPKArticleProtocol> article) {
  BOOL isValidCDN = article.cdnURL ?
      article.cdnURL.host && article.cdnURL.absoluteString.length :
      YES;
  return article.publisherURL.absoluteString.length && article.publisherURL.host && isValidCDN;
}

NS_ASSUME_NONNULL_END
