# AMP Viewer For iOS (AMPKit)

AMPKit is a native AMP viewer for iOS. It allows your iOS app to display AMP
articles in a native viewer with high performance scrolling. AMPKit is fully
customizable for your app and support prerendering of AMP articles. It can be
added to your iOS project in just a few lines.

## Quick Start
AMPKit is composed of several primary components:

*   The [AMPKViewController](https://github.com/ampproject/amp-viewer/blob/master/ios/AMPKit/AMPKViewController.m)
*   The [AMPKPrefetchController](https://github.com/ampproject/amp-viewer/blob/master/ios/AMPKit/AMPKPrefetchController.h)
*   The [AMPKViewerDataSource](https://github.com/ampproject/amp-viewer/blob/master/ios/AMPKit/ViewControllers/AMPKViewerDataSource.h)
*   The [AMPKArticle](https://github.com/ampproject/amp-viewer/blob/master/ios/AMPKit/Models/AMPKArticle.h)
*   The [AMPKViewer](https://github.com/ampproject/amp-viewer/blob/master/ios/AMPKit/AMPKViewer.h)

For the most part, you should not try to present an `AMPKViewer` or subclass
yourself. Instead, you should create one via an `AMPKPrefetchController`. In
addition to providing prefetching, the `AMPKPrefetchController` will validate
the URLs you pass to it before adding them to a data source and assigning the
data source to a viewer.

### AMPKViewController
As a default AMP Viewer, you can use AMPKViewController. If your app doesn't
need to customize the UX of the viewer, this Viewer will let you easily and
simply display AMP articles without much effort on your part.

### Adding AMPKit to your project

The recommended route is to add AMPKit via Cocoapods. First, you'll need to
install Cocoapods.

To install CocoaPods, run the following commands:

`sudo gem install cocoapods`
To integrate AMPKit into your existing app create a new Podfile:

```cd your-project-directory
pod init
````

Finally, add the AMPKit pod to your app's target:

```target "MyApp" do
  ...
  pod 'AMPKit'
end
````

#### Headers

AMPKit provides an umbrella header, [`AMPK.h`](https://github.com/ampproject/amp-viewer/blob/master/ios/AMPKit/AMPK.h)
for you to import when using or customizing AMPKit. In most cases, you shouldn't
need to manually import any additional headers.

### Using AMPKit

This section will help you with a basic AMPKit integration into your app.

Remember, the entry point for AMPKit in your app should be an
`AMPKPrefetchController`. From there, you can grab an instance of the AMP Viewer
to present.

#### AMPKPrefetchController

To instantiate a prefetch controller, simply `alloc init`

```objectivec
self.prefetchController = [[AMPKPrefetchController alloc] init];
```

Then, when you're ready to load a set of AMP articles into the viewer:

```objectivec
[self.prefetchController ampViewerWithArticles:self.ampArticles
                             prefetchedAtIndex:3];
```

This will create the viewer and start the prefetching at index 3.

Then, to present the viewer, simply present the current `ampViewController`
however your app would normally show a ViewController
(modally, pushed onto a nav stack ...)

```objectivec
[self presentViewController:self.prefetchController.ampViewController
                   animated:YES
                 completion:nil];
```

This will result in a blank viewer with no additional UI other than the swipable
AMPViewer. You can feel free to subclass, add headers, footers, and other UI to
match the style of your App.

#### AMPKArticle
To create an AMP article, you'll need 2 URLs:

*   AMP Article URL (the publisher's URL)
*   AMP CDN URL

If your data source does not have the CDN URL, you should try to get it first.
Using AMPKit without a CDN URL for each article is not advised. Using AMPKit in
this way will add ~1 second of latency to each AMP article which really hurts
the performance of AMP.

To create an AMP article, there's a convience method available for you:

```objectivec
[AMPKArticle articleWithURL:publisherURL cdnURL:cdnURL];
```

### Customizing AMPKit
The steps above will give you a generic AMPKit viewer without any customization.
After you subclass the `AMPKViewer` (to provide your UI), you'll need to
implement the `AMPKPrefetchProvider` in order to have your `AMPKViewer` subclass
returned. Then, set the AMPKPrefetchController's delegate to your object.

```objectivec
self.prefetchController.prefetchProvider = myProvider;
```

You'll implement the `newViewerWithDataSource:` method and return a new instance
of your `AMPKViewer` subclass using the data source passed:

```objectivec
- (AMPKViewer *)newViewerWithDataSource:(AMPKViewerDataSource *)dataSource {
  return [[MyAMPViewer alloc] initWithViewerDataSource:dataSource];
}
```

#### AMPKArticleProtocol
Optionally, if your app already has a model representing your data, you can
choose to conform your model to the `AMPKArticleProtocol` instead of using the
standard `AMPKArticle` class. Please make sure to synthesize all 3 properties
declared in the model and to also confrom your class to `NSCopying` and
`NSCoding`. Implement `encodeWithCoder:` , `initWithCoder:` , `copyWithZone:` ,
and `isEqual:`

#### AMPKViewerDataSource
Another option to customize is the data source. By default, AMPKit will assume
https://www.google.com as the base URL for the viewer. If your users might be
accessing from a different country, such as https://www.google.co.uk, you
should implement `defaultDataSource` and return an instance of the data source
that's been initalized with the correct URL for the current user.

## Implementation Demo
We have implemented a sample Demo as a strarting point to show how to use the
default AMPKViewController or as a starting point for customizing your own
AMPKViewer. You can check out the Demo Project by running `pod install` inside
AMPKitDemo directory.

The [AKDAmpViewer](https://github.com/ampproject/amp-viewer/blob/master/ios/AMPKitDemo/AMPKitDemo/AKDAmpViewer.m)
is the most simple starting point for making your own AMP viewer. 

Of particular importance is the [`AMPKViewerDelegate`](https://github.com/ampproject/amp-viewer/blob/master/ios/AMPKit/AMPKViewer.h#L102)
This has all the required methods for you to implement in order to properly
update your UI and internal record keeping. Additionally, as AMPKViewer 
is itself a UIPageViewController, you're free to implement any of the 
UIPageViewControllerDelegate methods. Just be sure to call `super` class'
method first. 

Also, there's the [`AMPKPresenterProtocol`](https://github.com/ampproject/amp-viewer/blob/master/ios/AMPKit/Protocols/AMPKPresenterProtocol.h)
to implement for opening external links that are clicked in the AMP document.

Note that none of these delegates are available in the AMPKViewController.
Instead, there's a single ['AMPKViewControllerDelegate'](https://github.com/ampproject/amp-viewer/blob/master/ios/AMPKit/AMPKViewController.h#L55)
you should use instead.
