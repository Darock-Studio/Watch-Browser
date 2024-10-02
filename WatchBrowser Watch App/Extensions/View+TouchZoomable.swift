//
//  View+TouchZoomable.swift
//  WatchBrowser
//
//  Created by memz233 on 10/1/24.
//

import SwiftUI
import Dynamic

extension View {
    @ViewBuilder
    func touchZoomable() -> some View {
        ZoomableRepresent(sourceView: self)
    }
    
    @ViewBuilder
    func withTouchZoomGesture(onPositionChange: @escaping (CGPoint) -> Void, onScaleChange: @escaping (CGFloat) -> Void) -> some View {
        ZoomableRepresent(sourceView: self, onPositionChange: onPositionChange, onScaleChange: onScaleChange)
    }
}

private struct ZoomableRepresent<T>: _UIViewRepresentable where T: View {
    let sourceView: T
    var onPositionChange: ((CGPoint) -> Void)?
    var onScaleChange: ((CGFloat) -> Void)?
    
    func makeUIView(context: Context) -> some NSObject {
        let hostingSource = Dynamic(_makeUIHostingView(sourceView))
        hostingSource.userInteractionEnabled = true
        
        let panGesture = Dynamic.UIPanGestureRecognizer.initWithTarget(context.coordinator, action: #selector(Coordinator.handlePanGesture(_:)))
        panGesture.delegate = context.coordinator
        panGesture.cancelsTouchesInView = false
        hostingSource.addGestureRecognizer(panGesture)
        
        let pinchGesture = Dynamic.UIPinchGestureRecognizer.initWithTarget(context.coordinator, action: #selector(Coordinator.handlePinchGesture(_:)))
        panGesture.delegate = context.coordinator
        panGesture.cancelsTouchesInView = false
        hostingSource.addGestureRecognizer(pinchGesture)
        
        return hostingSource.asObject!
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(_makeUIHostingView(sourceView), onPositionChange: onPositionChange, onScaleChange: onScaleChange)
    }
    
    @objcMembers
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let hostingSource: NSObject
        var onPositionChange: ((CGPoint) -> Void)?
        var onScaleChange: ((CGFloat) -> Void)?
        
        init(_ hostingSource: NSObject, onPositionChange: ((CGPoint) -> Void)? = nil, onScaleChange: ((CGFloat) -> Void)? = nil) {
            self.hostingSource = hostingSource
            self.onPositionChange = onPositionChange
            self.onScaleChange = onScaleChange
        }
        
        func handlePanGesture(_ panGesture: NSObject) {
            let panGesture = Dynamic(panGesture)
            let translation = panGesture.translationInView(panGesture.view.superview.asObject!).asCGPoint!
            if let onPositionChange {
                onPositionChange(translation)
                panGesture.setTranslation(CGPoint.zero, inView: hostingSource)
            } else {
                if panGesture.state == 1 || panGesture.state == 2 {
                    let centerPoint = panGesture.view.center.asCGPoint!
                    panGesture.view.center = CGPoint(x: centerPoint.x + translation.x, y: centerPoint.y + translation.y)
                    panGesture.setTranslation(CGPoint.zero, inView: hostingSource)
                }
            }
        }
        func handlePinchGesture(_ pinchGesture: NSObject) {
            let pinchGesture = Dynamic(pinchGesture)
            if pinchGesture.state == 1 || pinchGesture.state == 2 {
                let scale = pinchGesture.scale.asDouble!
                if let onScaleChange {
                    onScaleChange(scale)
                } else {
                    pinchGesture.view.transform = CGAffineTransform(scaleX: scale, y: scale)
                }
            }
        }
        
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}