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

@end

NS_ASSUME_NONNULL_END
