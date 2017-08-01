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

#import "AKDViewController.h"

#import "AMPK.h"
#import "AMPKViewController.h"
#import "AMPKHeaderView.h"
#import "AKDAmpViewer.h"

@interface AKDViewController () <AMPKViewControllerDelegate>
@end

@implementation AKDViewController {
  AKDAmpViewer *_ampViewer;
  AMPKViewController *_ampViewController;
  AMPKViewerDataSource *_dataSource1;
  AMPKViewerDataSource *_dataSource2;
  __weak IBOutlet UIButton *AKVCViewer;
  __weak IBOutlet UIButton *customViewer;
}
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    // The data source should be initialized with the domain name representing the google TLD of the
    // local/signed in user. Here, we hard code to google.com as an example. This base datasource
    // handles caching and pre-loading adjacent views for you automatically.
    NSURL *domainURL = [NSURL URLWithString:@"https://www.google.com"];
    _dataSource1 = [[AMPKViewerDataSource alloc] initWithDomainName:domainURL];
    _ampViewer = [[AKDAmpViewer alloc] initWithViewerDataSource:_dataSource1];
    _dataSource2 = [_dataSource1 copy];
    _ampViewController = [[AMPKViewController alloc] initWithViewerDataSource:_dataSource2];
    _ampViewController.AMPKViewControllerDelegate = self;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  // By setting the data source's URL's here, we start the pre-loading process so that the AMP
  // viewer and it's first several articles are instantly ready to show even before the user
  // triggers showing the AMP viewer.
  [_ampViewer.viewerDataSource setAmpArticles:[self sampleAMPArticles] usingHeaders:nil];
  [_ampViewController.viewerDataSource setAmpArticles:[self sampleAMPArticles] usingHeaders:nil];
}

- (IBAction)showCustomAmpViewer:(id)sender {
  [self presentViewController:_ampViewer animated:YES completion:NULL];
}

- (IBAction)showAmpViewController:(id)sender {
  [self presentViewController:_ampViewController animated:YES completion:NULL];
}

#pragma mark - AMPKViewController

- (void)AMPKCloseViewer:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Data Source

// This is just a sample to represent a set of AMP articles you might have to open from your app.
- (NSArray<AMPKArticle *>*)sampleAMPArticles {
  NSURL *one = [NSURL URLWithString:@"http://www.theverge.com/platform/amp/2016/4/25/11501484/what-in-the-world-is-obama-looking-at-in-virtual-reality"];
  NSURL *two = [NSURL URLWithString:@"http://mobile.nytimes.com/2016/04/26/us/politics/ted-cruz-john-kasich-donald-trump.amp.html"];
  NSURL *three = [NSURL URLWithString:@"http://www.bbc.co.uk/news/amp/36132887"];
  NSURL *four = [NSURL URLWithString:@"http://mobile.nytimes.com/2016/04/26/world/europe/obama-germany-speech.amp.html"];
  NSURL *five = [NSURL URLWithString:@"http://amp.usatoday.com/story/83503194/"];
  NSURL *six = [NSURL URLWithString:@"http://profootballtalk.nbcsports.com/2016/04/25/donald-trump-has-had-enough-declares-leave-tom-brady-alone/amp/"];
  NSURL *seven = [NSURL URLWithString:@"https://www.washingtonpost.com/amphtml/news/post-politics/wp/2016/04/25/clinton-knocks-donald-trump-for-country-club-lifestyle-big-jet-campaign/"];

  return @[[AMPKArticle articleWithURL:one],
           [AMPKArticle articleWithURL:two],
           [AMPKArticle articleWithURL:three],
           [AMPKArticle articleWithURL:four],
           [AMPKArticle articleWithURL:five],
           [AMPKArticle articleWithURL:six],
           [AMPKArticle articleWithURL:seven]];
}

@end

