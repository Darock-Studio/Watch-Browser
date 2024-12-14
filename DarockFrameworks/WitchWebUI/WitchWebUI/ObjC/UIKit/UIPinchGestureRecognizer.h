#if (defined(USE_UIKIT_PUBLIC_HEADERS) && USE_UIKIT_PUBLIC_HEADERS) || !__has_include(<UIKitCore/UIPinchGestureRecognizer.h>)
//
//  UIPinchGestureRecognizer.h
//  UIKit
//
//  Copyright (c) 2008-2018 Apple Inc. All rights reserved.
//

#import "CoreGraphics/CoreGraphics.h"
#import "UIKit/UIGestureRecognizer.h"
#import "UIKit/UIKitDefines.h"

NS_HEADER_AUDIT_BEGIN(nullability, sendability)

// Begins:  when two touches have moved enough to be considered a pinch
// Changes: when a finger moves while two fingers remain down
// Ends:    when both fingers have lifted

UIKIT_EXTERN API_AVAILABLE(ios(3.2)) API_UNAVAILABLE(tvos) NS_SWIFT_UI_ACTOR
@interface UIPinchGestureRecognizer : UIGestureRecognizer

@property (nonatomic)          CGFloat scale;               // scale relative to the touch points in screen coordinates
@property (nonatomic,readonly) CGFloat velocity;            // velocity of the pinch in scale/second

@end

NS_HEADER_AUDIT_END(nullability, sendability)

#else
#import "UIKitCore/UIPinchGestureRecognizer.h"
#endif
