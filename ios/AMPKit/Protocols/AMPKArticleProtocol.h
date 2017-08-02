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

NS_ASSUME_NONNULL_BEGIN

/**
 * Protocol used for creating model objects representing articles to open the in AMP viewer.
 * Alternatively, if you only need basic support, you may use the AMPKArticle class which
 * only implements these two concrete properities.
 * Note: The publisherURL is the only mandatory field. If the cdnURL is nil the viewer will default
 * to the old CDN address scheme. This is not recommended as it will add 100-2000ms of latentcy to
 * all AMP articles opened inside the viewer. Please provide both URLs in your implementation.
 * Please also implement isEqual: and copyWithZone: in your implementation.
 */
@protocol AMPKArticleProtocol <NSObject, NSCopying, NSCoding>

/** The URL for the AMP article on the publisher's site. */
@property(nonatomic) NSURL *publisherURL;

/** The URL for the article served from the AMP CDN. */
@property(nonatomic, nullable) NSURL *cdnURL;

/** The non-AMP version of this AMP article. */
@property(nonatomic, nullable) NSURL *canonicalURL;

@end

/**
 * Checks to see if two articles are considered equal for the purposes of the AMP viewer. This will
 * not check anything other than required properties.
 */
BOOL AMPKViewerShouldConsiderArticlesTheSame(id<AMPKArticleProtocol> article1,
                                             id<AMPKArticleProtocol> article2);

/**
 * Checks to see if the URLs in an AMP Article are valid for loading in the AMP Viewer. If they are
 * not valid they should not be loaded into an @c AMPKViewerDataSource as the behavior is undefined.
 */
BOOL AMPKArticleIsValid(id<AMPKArticleProtocol> article);

NS_ASSUME_NONNULL_END
