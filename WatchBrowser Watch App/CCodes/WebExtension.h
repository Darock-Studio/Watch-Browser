//
//  WebExtension.h
//  WatchBrowser
//
//  Created by memz233 on 2024/4/20.
//

#ifndef WebExtension_h
#define WebExtension_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

bool pIsMenuButtonDown;
bool pMenuShouldDismiss;
bool pShouldPresentVideoList;
id webView;
id webViewParentController;
NSTimer *videoCheckTimer;

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

@end

@interface WebExtensionDelegate : NSObject
- (void)webView:(id)view didFinishNavigation:(id)navigation;
@end

#endif /* WebExtension_h */
