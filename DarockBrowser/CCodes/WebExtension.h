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

bool pShouldPresentVideoList;
bool pShouldPresentImageList;
bool pShouldPresentBookList;
bool pShouldPresentAudioList;
id webViewParentController;
NSUserActivity* globalWebBrowsingUserActivity;

@interface WebExtension : NSObject

@end

#endif /* WebExtension_h */
