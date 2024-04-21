//
//  WebExtension.m
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/20.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "WebExtension.h"

@implementation WebExtension : NSObject

+(id) getBindedButtonWithSelector: (NSString *)selector button:(id) button {
    id cbtn = button;
    [cbtn addTarget:self action:NSSelectorFromString(selector) forControlEvents:1 << 0];
    
    return cbtn;
}
+(void) setWebViewDelegate {
//    Protocol *protocol = objc_getProtocol("WKNavigationDelegate");
//    class_addProtocol([WebExtensionDelegate class], protocol);
//    [webView performSelector:NSSelectorFromString(@"setNavigationDelegate") withObject:[[WebExtensionDelegate alloc] init]];
}

// Externald Method Start
+(void) menuButtonClicked {
    pIsMenuButtonDown = true;
}
+(void) DismissMenu {
    pMenuShouldDismiss = true;
}
+(void) WKGoBack {
    [webView performSelector:NSSelectorFromString(@"goBack")];
    pMenuShouldDismiss = true;
}
+(void) WKGoForward {
    [webView performSelector:NSSelectorFromString(@"goForward")];
    pMenuShouldDismiss = true;
}
+(void) WKReload {
    [webView performSelector:NSSelectorFromString(@"reload")];
    pMenuShouldDismiss = true;
}

+(void) DismissWebView {
    [webViewParentController performSelector:NSSelectorFromString(@"dismissModalViewControllerAnimated:") withObject:@(true)];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [webViewParentController performSelector:NSSelectorFromString(@"dismissModalViewControllerAnimated:") withObject:@(true)];
    });
}
+(void) PresentVideoList {
    [videoCheckTimer invalidate];
    [self DismissWebView];
    pShouldPresentVideoList = true;
}
// Externald Method End

@end

@implementation WebExtensionDelegate

- (void)webView:(id)view didFinishNavigation:(id)navigation {
    NSLog(@"Finished Navigation");
}

@end
