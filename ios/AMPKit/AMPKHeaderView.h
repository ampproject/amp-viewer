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

@class MDCFlatButton;

NS_ASSUME_NONNULL_BEGIN

/**
 * A basic AMP header which provides UI for the URL, AMP icon, share, and close.
 */
@interface AMPKHeaderView : UIView

/**
 * Factory method to create a new AMP header view. Loads from the nib.
 */
+ (instancetype)ampHeaderView;

/**
 * The close button. Tapping will call the AMPKViewerClosed method on the
 * AMPKViewerDelegate in the AMPKViewController.
 */
@property(nonatomic, readonly) MDCFlatButton *closeButton;

/**
 * The share button. Tapping will display the system share sheet for the
 * canonical URL of the current AMP document. Access to the onTap and completion
 * callback for the share dialog provided by the AMPKViewerDelegate in the
 * AMPKViewController.
 */
@property(nonatomic, readonly) MDCFlatButton *shareButton;

/**
 * The page control indicating the current and total number of AMP documents.
 * This should be directly configured.
 */
@property(nonatomic, readonly) UIPageControl *pageControl;

/**
 * Displays the host for the current AMP document.
 */
@property(nonatomic, readonly) UILabel *urlLabel;

/**
 * The tint color for the AMP header. This is a convenience method for setting
 *  the color of each button separately. Defaults to black.
 */
@property(nonatomic) UIColor *tintColor;

/**
 * Set this to the topLayoutGuide of the AMP Viewer this header is added to.
 * The header will auto-adjust to push the header content to the bottom of the
 * topLayoutGuide as to not obstruct the status bar.
 */
@property(nonatomic, nullable) id <UILayoutSupport> topLayoutGuide;

@end

NS_ASSUME_NONNULL_END
