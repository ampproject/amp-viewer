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

#import "AMPKArticle.h"
#import "AMPKPrefetchController.h"
#import "AMPKPresenterProtocol.h"
#import "AMPKViewer.h"
#import "AMPKViewerDataSource.h"
#import "AMPKWebViewerViewController.h"

/**
 * The field to set in the @c headers of your @c AMPKPrefetchController call if you wish to
 * identify your app in some way other than your app's bundle identifier.
 */
extern NSString * const AMPKHeaderNameField;
