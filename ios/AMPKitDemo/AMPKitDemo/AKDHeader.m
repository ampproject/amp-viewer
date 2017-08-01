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

#import "AKDHeader.h"

@implementation AKDHeader {
  UILabel *_titleLabel;
  UILabel *_urlLabel;
  UIButton *_closeButton;
  UIButton *_shareButton;
  UIStackView *_rootGrouping;
  UIStackView *_buttonsStack;
  UIStackView *_labelsStack;
}

- (instancetype)initWithTitle:(NSString *)title atURL:(NSURL *)url {
  self = [super initWithFrame:CGRectZero];
  if (self) {
    _title = title;
    _url = url;

    [self setupButtons];
    [self setupLabels];

    _rootGrouping = [[UIStackView alloc] initWithArrangedSubviews:@[_buttonsStack, _labelsStack]];
    _rootGrouping.translatesAutoresizingMaskIntoConstraints = NO;
    _rootGrouping.axis = UILayoutConstraintAxisVertical;
    [self addSubview:_rootGrouping];

    [[_rootGrouping widthAnchor] constraintEqualToAnchor:[self widthAnchor]].active = YES;
    [[_rootGrouping leadingAnchor] constraintEqualToAnchor:[self leadingAnchor]].active = YES;
    [[_rootGrouping topAnchor] constraintEqualToAnchor:[self topAnchor] constant:20].active = YES;
    [[_rootGrouping bottomAnchor] constraintEqualToAnchor:[self bottomAnchor]].active = YES;
  }
  return self;
}

- (void)setupLabels {
  _titleLabel = [[UILabel alloc] init];
  _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _titleLabel.font = [UIFont systemFontOfSize:13];

  _urlLabel = [[UILabel alloc] init];
  _urlLabel.translatesAutoresizingMaskIntoConstraints = NO;
  _urlLabel.font = [UIFont systemFontOfSize:10];

  [self updateLabels];

  _labelsStack = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _urlLabel]];
  _labelsStack.axis = UILayoutConstraintAxisVertical;
}

- (void)setupButtons {
  _closeButton = [[UIButton alloc] init];
  [_closeButton setTitle:@"Close" forState:UIControlStateNormal];
  _closeButton.translatesAutoresizingMaskIntoConstraints = NO;

  _shareButton = [[UIButton alloc] init];
  [_shareButton setTitle:@"Share" forState:UIControlStateNormal];
  _shareButton.translatesAutoresizingMaskIntoConstraints = NO;

  UIStackView *containerStack = [[UIStackView alloc] initWithArrangedSubviews:@[_closeButton,
                                                                                _shareButton]];
  containerStack.axis = UILayoutConstraintAxisHorizontal;
  containerStack.alignment = UIStackViewAlignmentCenter;
  containerStack.distribution = UIStackViewDistributionEqualSpacing;
  containerStack.spacing = 14;

  UIView *spacerView = [[UIView alloc] init];
  spacerView.backgroundColor = [UIColor clearColor];

  _buttonsStack = [[UIStackView alloc] initWithArrangedSubviews:@[spacerView, containerStack]];
  [spacerView.heightAnchor constraintEqualToAnchor:containerStack.heightAnchor].active = YES;

  _buttonsStack.axis = UILayoutConstraintAxisHorizontal;
  _buttonsStack.spacing = 14;
}

#pragma mark - Public update method

- (void)updateLabels {
  _titleLabel.text = _title;
  _urlLabel.text = [_url host];
}

- (void)shareArticle {
}

@end
