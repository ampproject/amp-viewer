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

#import <UIKit/UIKit.h>

// This is our simple custom header. You could add a page indicator here as well or other UI
// elements to indicate to the user that they can swipe between articles.
@interface AKDHeader : UIView
- (instancetype)initWithTitle:(NSString *)title atURL:(NSURL *)url NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_UNAVAILABLE;
- (instancetype)initWithCoder:(NSCoder *)aDecoder NS_UNAVAILABLE;
- (void)updateLabels;

@property(nonatomic, copy) NSString *title;
@property(nonatomic) NSURL *url;
@property(nonatomic, readonly) UIButton *closeButton;
@property(nonatomic, readonly) UIButton *shareButton;
@end
