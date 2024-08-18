//
//  SFSafariViewControllerDelegate.h
//  WatchBrowser
//
//  Created by memz233 on 2024/8/18.
//

#ifndef SFSafariViewControllerDelegate_h
#define SFSafariViewControllerDelegate_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SFSafariViewControllerDelegate <NSObject>
@optional

/*! @abstract Called when the view controller is about to show UIActivityViewController after the user taps the action button.
 @param URL the URL of the web page.
 @param title the title of the web page.
 @result Returns an array of UIActivity instances that will be appended to UIActivityViewController.
 */
- (NSArray<UIActivity *> *)safariViewController:(id)controller activityItemsForURL:(NSURL *)URL title:(nullable NSString *)title;

/*! @abstract Delegate callback called when the user taps the Done button. Upon this call, the view controller is dismissed modally. */
- (void)safariViewControllerDidFinish:(id)controller;

/*! @abstract Invoked when the initial URL load is complete.
 @param didLoadSuccessfully YES if loading completed successfully, NO if loading failed.
 @discussion This method is invoked when SFSafariViewController completes the loading of the URL that you pass
 to its initializer. It is not invoked for any subsequent page loads in the same SFSafariViewController instance.
 */
- (void)safariViewController:(id)controller didCompleteInitialLoad:(BOOL)didLoadSuccessfully;

/*! @abstract Called when the browser is redirected to another URL while loading the initial page.
 @param URL The new URL to which the browser was redirected.
 @discussion This method may be called even after -safariViewController:didCompleteInitialLoad: if
 the web page performs additional redirects without user interaction.
 */
- (void)safariViewController:(id)controller initialLoadDidRedirectToURL:(NSURL *)URL API_AVAILABLE(ios(11.0));

/*! @abstract Called when the user opens the current page in the default browser by tapping the toolbar button.
 */
- (void)safariViewControllerWillOpenInBrowser:(id)controller NS_SWIFT_NAME(safariViewControllerWillOpenInBrowser(_:)) API_AVAILABLE(ios(14.0));

@end

NS_ASSUME_NONNULL_END

#endif /* SFSafariViewControllerDelegate_h */
