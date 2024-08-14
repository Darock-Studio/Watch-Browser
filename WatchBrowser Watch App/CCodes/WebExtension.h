//
//  WebExtension.h
//  WatchBrowser
//
//  Created by memz233 on 2024/4/20.
//

#ifndef WebExtension_h
#define WebExtension_h

#import <UIKit/UIKit.h>
#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>
#import "WebKit/WebKit.h"

bool pIsMenuButtonDown;
bool pMenuShouldDismiss;
bool pShouldPresentVideoList;
bool pShouldPresentImageList;
bool pShouldPresentBookList;
bool pShouldPresentAudioList;
bool dismissListsShouldRepresentWebView;
WKWebView* webViewObject;
id webViewParentController;
NSUserActivity* globalWebBrowsingUserActivity;

@interface WebExtension : NSObject

+(id) getBindedButtonWithSelector: (NSString *)selector button:(id) button;
+(void) PresentVideoList;
+(void) PresentBookList;
+(void) PresentAudioList;
+(void) DismissWebView;

@end

#endif /* WebExtension_h */
