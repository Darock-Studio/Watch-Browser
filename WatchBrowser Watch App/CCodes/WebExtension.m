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
    [[AdvancedWebViewController shared] presentBrowsingMenu];
}
// Externald Method End

@end

#pragma clang diagnostic pop
