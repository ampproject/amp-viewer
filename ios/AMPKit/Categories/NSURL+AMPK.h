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

/** Provide a set of URL manipulation methods for changing AMP URLs. */
@interface NSURL (AMP)

/** Generate the CDN proxy address from the current URL. */
- (NSURL *)ampk_ProxiedURL;

/**
 * Set the hash fragment to the fragment used for proxy initialization of the current URL. Note,
 * this will overwrite any current hash fragment as the proxy does not allow any fragments in the
 * URL.
 * @param domain should be a Google domain of current user's country. Ex: https//:xxx.google.com/
 */
- (NSURL *)URLBySettingProxyHashFragmentsForDomain:(NSURL *)domain;

/**
 * Returns the path of the URL but including the trailing slash if applicable. NSURL trims this
 * slash by default and AMP must keep it.
 */
- (NSString *)ampPath;

/**
 * Returns if the current URL matches the given CDN URL. This method is agnostic to checking the
 * equivalence of CURLS vs non-CURLS CDN URLs. This way, you can check if a non-CURLS URL matches to
 * its CURLS counterpart.
 * @param source The CDN URL you want to compare the current URL to.
 */
- (BOOL)matchesCDNURL:(NSURL *)source;

/**
 * Returns the sanitized version of the CDN URL. For AMPKit, CDN URLs that include the AMP JS
 * version via the "v" parameter or that try to directly initialize the runtime cannot be used. This
 * method should be called on any URL you try to pass to AMPKit as a CDN URL to ensure it is in a
 * safe form. Returns nil if the URL cannot be recognized as a CDN URL.
 */
- (nullable NSURL *)sanitizedCDNURL;

@end

NS_ASSUME_NONNULL_END
