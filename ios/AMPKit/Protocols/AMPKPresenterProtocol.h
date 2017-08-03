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
#import <UIKit/UIKit.h>

@protocol AMPKPaywallAccessProtocol;

/** This protocol allows the caller to present a customer viewController. */
@protocol AMPKPresenterProtocol <NSObject>

/** Present a customize viewer when user tap on an embedded link. */
- (void)presentEmbeddedLinkRequest:(NSURLRequest *)embeddedLinkRequest
                fromViewController:(UIViewController *)fromViewController;

/** Present a Access viewer for user's login information. */
- (void)presentAccessUrl:(NSURL *)accessUrl
           requestPrefix:(NSString *)identifier
               requestId:(NSString *)requestId
      fromViewController:(UIViewController <AMPKPaywallAccessProtocol>*)fromViewController;

@end

@protocol AMPKPaywallAccessProtocol <NSObject>

/**
 * When user has completed the login screen, caller must call this method to complete the paywall
 * access.
 */
- (void)paywallAccessCompletionWithToken:(NSString *)respondToken
                               requestId:(NSString *)requestId;

@end
