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

bool pIsMenuButtonDown;
bool pMenuShouldDismiss;
bool pShouldPresentVideoList;
bool pShouldPresentImageList;
bool pShouldPresentBookList;
bool pShouldPresentAudioList;
bool dismissListsShouldRepresentWebView;
id webViewObject;
id webViewParentController;
NSUserActivity* globalWebBrowsingUserActivity;

@interface UIView : NSObject
- (void)setTintColor:(id)color;
- (void)setBackgroundColor:(id)color;
@end

@interface UIControl : UIView
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(unsigned long long)events;
@end

@interface WebExtension : NSObject

+(id) getBindedButtonWithSelector: (NSString *)selector button:(id) button;
+(void) setWebViewDelegate;
+(void) setUserScriptDelegateWithController: (id)controller;
+(void) PresentVideoList;
+(void) PresentBookList;
+(void) PresentAudioList;
+(void) DismissWebView;

@end

@interface WebExtensionDelegate : NSObject
- (void)webView:(id)view didStartProvisionalNavigation:(id)navigation;
- (void)webView:(id)view didFinishNavigation:(id)navigation;
- (void)webView:(id)view didFailNavigation:(id)navigation withError:(NSError *)error;
- (void)webView:(id)view didFailProvisionalNavigation:(id)navigation withError:(NSError *)error;
- (void)webViewWebContentProcessDidTerminate:(id)webView;
@end
@interface WebUIDelegate : NSObject
- (id)webView:(id)webView createWebViewWithConfiguration:(id)configuration forNavigationAction:(id)navigationAction windowFeatures:(id)windowFeatures;
@end
@interface WebScriptMessageHandler : NSObject
- (void)userContentController:(id)userContentController didReceiveScriptMessage:(id)message;
@end

#endif /* WebExtension_h */
