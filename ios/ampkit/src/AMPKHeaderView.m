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

#import "AMPKHeaderView.h"

#import "MaterialButtons.h"

NS_ASSUME_NONNULL_BEGIN

@interface AMPKHeaderView ()

@property(unsafe_unretained, nonatomic) IBOutlet MDCFlatButton *closeButton;
@property(unsafe_unretained, nonatomic) IBOutlet MDCFlatButton *shareButton;
@property(unsafe_unretained, nonatomic) IBOutlet UIImageView *ampIcon;
@property(unsafe_unretained, nonatomic) IBOutlet UILabel *urlLabel;
@property(unsafe_unretained, nonatomic) IBOutlet UIPageControl *pageControl;
@property(unsafe_unretained, nonatomic) IBOutlet UIStackView *stackView;
@property(nonatomic) IBOutlet NSLayoutConstraint *stackViewTopAnchor;

@end

@implementation AMPKHeaderView

+ (instancetype)ampHeaderView {
  NSArray *nibObjs = [[AMPKHeaderView reusableNib] instantiateWithOwner:self options:nil];
  AMPKHeaderView *headerView = [nibObjs firstObject];
  return headerView;
}

+ (UINib *)reusableNib {
  static UINib *reusableNib = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    reusableNib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
  });
  return reusableNib;
}

- (void)awakeFromNib {
  [super awakeFromNib];
  self.closeButton.contentEdgeInsets = UIEdgeInsetsZero;
  self.shareButton.contentEdgeInsets = UIEdgeInsetsZero;
  self.ampIcon.tintColor = [UIColor lightGrayColor];
  self.tintColor = [UIColor blackColor];
}

#pragma mark - Setters

- (void)setTintColor:(UIColor *)tintColor {
  _tintColor = tintColor;
  self.shareButton.imageView.tintColor = tintColor;
  self.closeButton.imageView.tintColor = tintColor;
}

- (void)setTopLayoutGuide:(nullable id<UILayoutSupport>)topLayoutGuide {
  _topLayoutGuide = topLayoutGuide;
  if (topLayoutGuide) {
    NSLayoutConstraint *customTop =
        [self.stackView.topAnchor constraintEqualToAnchor:topLayoutGuide.bottomAnchor];
    customTop.priority = UILayoutPriorityRequired;
    customTop.active = YES;
  } else {
    self.stackViewTopAnchor.active = YES;
  }
}

@end

NS_ASSUME_NONNULL_END
