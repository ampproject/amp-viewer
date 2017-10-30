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

NS_ASSUME_NONNULL_BEGIN

static NSString *const kDefaultAMPProxyPrefix = @"https://cdn.ampproject.org";

static NSDictionary *kAMPProxyBasePathMapping(void) {
  return @{ @"http" : @"/c/", @"https" : @"/c/s/" };
}
static NSDictionary *kAMPSharingBasePathMapping(void) {
  return @{ @"http" : @"/amp/", @"https" : @"/amp/s/" };
}

// These are a set of query params that if set should be removed from the input CDN URL. These are
// either invalid for AMPKit or are manually set by AMPKit later and should be ignored as input.
static NSArray *kAMPRuntimeQueryParamsBlackList(void) {
  return @[@"webview", @"dialog", @"viewport", @"visibilityState", @"prerenderSize", @"amp_js_v"];
}

@implementation NSURL (AMP)

- (nullable NSURL *)sanitizedCDNURL {
  if (![self isCDNURL]) {
    return nil;
  } else if ([self needsCDNSanitization]) {
    NSURLComponents *components = [NSURLComponents componentsWithString:self.absoluteString];
    NSMutableArray *pathComponents = [self.pathComponents mutableCopy];
    if ([self isFirstPathComponentEmpty]) {
      [pathComponents removeObjectAtIndex:0];
    }
    // We need to include the leading "/" since this is the first path component.
    pathComponents[0] = @"/c";
    // Remember to append the trailing '/' to the new path components if it existed in the old path.
    // By default, iOS will strip this. Some publishers are very sensitive to this slash so we need
    // to keep it.
    if ([components.path hasSuffix:@"/"]) {
      NSString *lastComponent = [pathComponents lastObject];
      lastComponent = [lastComponent stringByAppendingString:@"/"];
      pathComponents[pathComponents.count - 1] = lastComponent;
    }
    components.path = [pathComponents componentsJoinedByString:@"/"];
    NSMutableArray<NSURLQueryItem *> *queryItems = [[components queryItems] mutableCopy];
    for (NSURLQueryItem *item in components.queryItems) {
      if ([kAMPRuntimeQueryParamsBlackList() containsObject:item.name]) {
        [queryItems removeObject:item];
      }
    }
    components.query = nil;
    components.queryItems = (queryItems.count == 0 ? nil : queryItems);
    components.fragment = nil;
    return [components URL];
  }
  return self;
}

- (BOOL)isCDNURL {
  NSURL *defaultCDNURL = [NSURL URLWithString:kDefaultAMPProxyPrefix];
  // The path should have at a minimum /c/<something> where iOS counts the leading "/" as a
  // component.
  if ([self.host hasSuffix:defaultCDNURL.host] && self.pathComponents.count > 2) {
    NSString *secondPathComponent = self.pathComponents[1];
    return [secondPathComponent isEqualToString:@"c"] || [secondPathComponent isEqualToString:@"v"];
  }
  return NO;
}

- (BOOL)needsCDNSanitization {
  return [self isSpecifyingManualVersion] || self.query || self.fragment;
}

- (BOOL)isSpecifyingManualVersion {
  return [[self pathComponents][1] isEqualToString:@"v"];
}

- (BOOL)isFirstPathComponentEmpty {
  return [[self pathComponents][0] isEqualToString:@"/"];
}

// We need to validate hostname match for both CURLS and non-CURLS addresses (which get redirects).
// If the non-CURLS adddress is redirected to CURLS, the host name won't match, but, the path still
// will and the source host name will be a subdomain (cdn.ampproject.org) of the new CURLS address.
- (BOOL)matchesCDNURL:(NSURL *)source {
  NSURL *baseProxyURL = [NSURL URLWithString:kDefaultAMPProxyPrefix];
  if ([self.host isEqualToString:source.host]) {
    return YES;
  } else if ([source.host hasSuffix:baseProxyURL.host] &&
             [self.lastPathComponent isEqualToString:source.lastPathComponent]) {
    return YES;
  }
  return NO;
}

/** Returns the authority of the URL, which is the host + port if the port is not 80. */
- (NSString *)authority {
  NSMutableString *authority = [[self host] mutableCopy];
  NSNumber *port = [self port];
  if (port && ![port isEqualToNumber:@(80)]) {
    [authority appendFormat:@":%@", port];
  }
  return authority;
}

- (NSString *)basePathForMapping:(NSDictionary *)mapping {
  NSString *scheme = [self scheme];
  if (!scheme) {
    return mapping[@"https"];
  } else if (![mapping objectForKey:scheme]) {
    return mapping[@"https"];
  } else {
    return mapping[scheme];
  }
}

// Because [NSURL path] trims trailing / from URL paths, we need to check the absolute string and
// add the trailing slash back if it exists. Some publishers are sensitive to this slash and we
// are not allowed to modify the URL passed to us in any way including triming this trailing /.
// Note: This assumes the url doesn't include hash or query parameters which for AMP url's is a safe
// assumption to make. Also, note, NSURL does include the trailing / if the path is only a / like
// www.google.com/ so we don't add an extra slash in this case.
- (NSString *)ampPath {
  NSString *path = self.path;
  NSString *urlAsString = self.absoluteString;
  if ([urlAsString hasSuffix:@"/"] && ![self.path isEqualToString:@"/"]) {
    path = [path stringByAppendingString:@"/"];
  }
  return path;
}

- (NSString *)fragmentForProxyForDomain:(NSURL *)domain {
  NSCharacterSet *characterSet = [NSCharacterSet URLHostAllowedCharacterSet];
  NSString *origin =
      [[domain absoluteString] stringByAddingPercentEncodingWithAllowedCharacters:characterSet];
  NSString *viewingURL = [[[self ampk_WebViewerURLForDomain:domain] absoluteString]
                              stringByAddingPercentEncodingWithAllowedCharacters:characterSet];
  NSMutableString *fragment = [NSMutableString stringWithFormat:@"origin=%@", origin];
  NSString *constants =
      @"&webview=1&dialog=1&viewport=natural&visibilityState=inactive&prerenderSize=1";
  [fragment appendString:constants];
  [fragment appendFormat:@"&viewerUrl=%@", viewingURL];

  return fragment;
}

- (NSURL *)ampk_ProxiedURL {
  NSURLComponents *components = [[NSURLComponents alloc] initWithString:kDefaultAMPProxyPrefix];
  [components setQuery:[self query]];
  [components setFragment:[self fragment]];
  NSURL *url = [components URL];
  url = [url URLByAppendingPathComponent:[self basePathForMapping:kAMPProxyBasePathMapping()]];
  url = [url URLByAppendingPathComponent:[self authority]];
  url = [url URLByAppendingPathComponent:[self ampPath]];

  return url;
}

- (NSURL *)URLBySettingProxyHashFragmentsForDomain:(NSURL *)domain {
  // Use URLComponents to ensure we nil out any existing fragment that was passed in as part of the
  // host URL. Then, append the encoded host string manually. Since the fragment we set is encoded
  // using the host URL encoding set instead of the fragment URL set, this has to be done manually
  // instead of using the setFragment on NSURLComponent.
  NSAssert([domain.scheme hasPrefix:@"http"],
             @"The AMP domain must include the http(s) scheme");
  NSAssert([domain.host containsString:@".google."], @"The AMP domain host must be google");
  NSURLComponents *components = [[NSURLComponents alloc] initWithURL:self
                                             resolvingAgainstBaseURL:NO];
  [components setFragment:nil];
  NSString *fragmentString =
      [NSString stringWithFormat:@"#%@", [self fragmentForProxyForDomain:domain]];
  NSString *urlString =  [[components string] stringByAppendingString:fragmentString];
  return [NSURL URLWithString:urlString];
}

- (NSURL *)ampk_WebViewerURLForDomain:(NSURL *)domain {
  NSURLComponents *components = [[NSURLComponents alloc] init];
  [components setHost:[domain host]];
  [components setScheme:@"https"];
  [components setQuery:[self query]];
  [components setFragment:[self fragment]];
  NSURL *url = [components URL];
  url = [url URLByAppendingPathComponent:[self basePathForMapping:kAMPSharingBasePathMapping()]];
  url = [url URLByAppendingPathComponent:[self authority]];
  url = [url URLByAppendingPathComponent:[self ampPath]];

  return url;
}

@end

NS_ASSUME_NONNULL_END
