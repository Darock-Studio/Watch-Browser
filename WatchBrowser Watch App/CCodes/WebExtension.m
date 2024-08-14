//
//  WebExtension.m
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/20.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "WebExtension.h"
#import "UIKit/UIButton.h"
#import "DarockBrowser-Swift.h"

id webNavigationDelegate;
id webUIDelegate;
id webScriptDelegate;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation WebExtension : NSObject

+(id) getBindedButtonWithSelector: (NSString *)selector button:(UIButton *) button {
    id cbtn = button;
    [cbtn addTarget:self action:NSSelectorFromString(selector) forControlEvents:1 << 6];
    
    return cbtn;
}

// Externald Method Start
+(void) menuButtonClicked {
    pIsMenuButtonDown = true;
}
+(void) DismissMenu {
    pMenuShouldDismiss = true;
}
+(void) WKGoBack {
    [webViewObject performSelector:NSSelectorFromString(@"goBack")];
    pMenuShouldDismiss = true;
}
+(void) WKGoForward {
    [webViewObject performSelector:NSSelectorFromString(@"goForward")];
    pMenuShouldDismiss = true;
}
+(void) WKReload {
    [webViewObject performSelector:NSSelectorFromString(@"reload")];
    pMenuShouldDismiss = true;
}
+(void) ArchiveCurrentPage {
    [WEBackSwift createWebArchive];
}
+(void) DismissWebView {
    [webViewParentController performSelector:NSSelectorFromString(@"dismissModalViewControllerAnimated:") withObject:@(true)];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [webViewParentController performSelector:NSSelectorFromString(@"dismissModalViewControllerAnimated:") withObject:@(true)];
    });
    [WEBackSwift storeWebTab];
    if (globalWebBrowsingUserActivity) {
        [globalWebBrowsingUserActivity invalidate];
    }
}
+(void) PresentVideoList {
    [self DismissWebView];
    pShouldPresentVideoList = true;
    dismissListsShouldRepresentWebView = true;
}
+(void) PresentImageList {
    [self DismissWebView];
    pShouldPresentImageList = true;
    dismissListsShouldRepresentWebView = true;
}
+(void) PresentAudioList {
    [self DismissWebView];
    pShouldPresentAudioList = true;
    dismissListsShouldRepresentWebView = true;
}
+(void) PresentBookList {
    [self DismissWebView];
    pShouldPresentBookList = true;
    dismissListsShouldRepresentWebView = true;
}
// Externald Method End

@end

#pragma clang diagnostic pop
