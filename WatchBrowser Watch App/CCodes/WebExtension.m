//
//  WebExtension.m
//  WatchBrowser Watch App
//
//  Created by memz233 on 2024/4/20.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "WebExtension.h"
#import "DarockBrowser-Swift.h"

id webNavigationDelegate;
id webUIDelegate;
id webScriptDelegate;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@implementation WebExtension : NSObject

+(id) getBindedButtonWithSelector: (NSString *)selector button:(id) button {
    id cbtn = button;
    [cbtn addTarget:self action:NSSelectorFromString(selector) forControlEvents:1 << 6];
    
    return cbtn;
}
+(void) setWebViewDelegate {
    webNavigationDelegate = [[WebExtensionDelegate alloc] init];
    [webViewObject setValue:webNavigationDelegate forKey:@"navigationDelegate"];
    webUIDelegate = [[WebUIDelegate alloc] init];
    [webViewObject setValue:webUIDelegate forKey:@"UIDelegate"];
}
+(void) setUserScriptDelegateWithController: (id)controller {
    webScriptDelegate = [[WebScriptMessageHandler alloc] init];
    [controller performSelector:NSSelectorFromString(@"addScriptMessageHandler:name:") withObject:webScriptDelegate withObject:@"logHandler"];
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
}
+(void) PresentVideoList {
    [videoCheckTimer invalidate];
    [self DismissWebView];
    pShouldPresentVideoList = true;
}
+(void) PresentImageList {
    [videoCheckTimer invalidate];
    [self DismissWebView];
    pShouldPresentImageList = true;
}
// Externald Method End

+ (BOOL)hooked_handlesURLScheme:(NSString *)urlScheme {
    return NO;
}

@end

@implementation WebExtensionDelegate

- (void)webView:(id)view didStartProvisionalNavigation:(id)navigation {
    [[[WESwiftDelegate alloc] init] webView:view didStartProvisionalNavigation:navigation];
}
- (void)webView:(id)view didFinishNavigation:(id)navigation {
    [[[WESwiftDelegate alloc] init] webView:view didFinishNavigation:navigation];
}
- (void)webView:(id)view didFailNavigation:(id)navigation withError:(NSError *)error {
    [[[WESwiftDelegate alloc] init] webView:view didFailNavigation:navigation withError:error];
}
- (void)webView:(id)view didFailProvisionalNavigation:(id)navigation withError:(NSError *)error {
    [[[WESwiftDelegate alloc] init] webView:view didFailProvisionalNavigation:navigation withError:error];
}
- (void)webViewWebContentProcessDidTerminate:(id)webView {
    [[[WESwiftDelegate alloc] init] webViewWebContentProcessDidTerminate:webView];
}

@end

@implementation WebUIDelegate

- (id)webView:(id)webView createWebViewWithConfiguration:(id)configuration forNavigationAction:(id)navigationAction windowFeatures:(id)windowFeatures {
    return [[[WESwiftDelegate alloc] init] webView:webView createWebViewWith:configuration for:navigationAction windowFeatures:windowFeatures];
}

@end

@implementation WebScriptMessageHandler

- (void)userContentController:(id)userContentController didReceiveScriptMessage:(id)message {
    [[[WESwiftDelegate alloc] init] userContentController:userContentController didReceive:message];
}

@end

#pragma clang diagnostic pop
