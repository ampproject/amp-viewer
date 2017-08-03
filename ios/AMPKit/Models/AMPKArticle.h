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

#import "AMPKArticleProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Generic model for AMP articles shown in the AMP viewer. To create your own model either subclass
 * or create your own object that conforms to AMPKArticleProtocol.
 */
@interface AMPKArticle : NSObject <AMPKArticleProtocol, NSCopying, NSCoding>

/**
 * Creates an AMPKArticle with only the publisher's URL.
 * @param url The Publisher's URL for this AMP article.
 * Note: This method is not recommended for production use as this method will not set a CDN URL.
 * This results in the non-CURLS CDN URL being generated which will result in extra latency in
 * each article open. The preferred method is to provide a CDN URL as well.
 */
+ (instancetype)articleWithURL:(NSURL *)url;

/**
 * Creates an AMPKArticle with both the publisher's URL and CDN URL.
 * @param url The Publisher's URL for this AMP article.
 * @param cdnURL The CDN URL for this AMP article.
 */
+ (instancetype)articleWithURL:(NSURL *)url cdnURL:(nullable NSURL *)cdnURL;

@property(nonatomic) NSURL *publisherURL;
@property(nonatomic, nullable) NSURL *cdnURL;
@property(nonatomic, nullable) NSURL *canonicalURL;

@end

NS_ASSUME_NONNULL_END
