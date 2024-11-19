//
//  WKWebView+.swift
//  WatchBrowser
//
//  Created by memz233 on 2024/8/20.
//

// rdar://so?64677941
extension WKWebView {
    /// Type of HTML element to get from DOM
    enum ElementType {
        /// ID Element
        case id
        /// Class element
        case `class`
    }
    
    /// List of errors for WKWebView injection
    enum InjectionError: Error {
        /// The Listener is already added
        case listenerAlreadyAdded
    }
    
    /// Changes the CSS Visibiltiy
    /// - Parameters:
    ///   - elementID: The name of the element
    ///   - isVisible: Whether or not is visible
    ///   - elementType: The type of element to get
    ///   - completion: Callback triggered when script has been appended to WKWebView
    func changeCSSVisibility(elementID: String, isVisible: Bool, elementType: ElementType, completion: ((Error?) -> Void)? = nil) {
        let script: String
        
        switch elementType {
        case .id:
            script = "document.getElementById('\(elementID)').style.display = \(isVisible ? "'block'" : "'none'");"
        case .class:
            script = """
            [].forEach.call(document.querySelectorAll('.\(elementID)'), function(el) {
                el.style.display = \(isVisible ? "'block'" : "'none'");
            });
            """
        }
        
        evaluateJavaScript(script, completionHandler: { _, error in
            completion?(error)
        })
    }
    
    /// Adds a event listener that will be call on WKScriptMessageHandler - didReceiveMessage
    /// - Parameters:
    ///   - elementID: The name of the element
    ///   - callbackID: The ID for the callback
    ///   - elementType: The type of element to get
    ///   - completion: Callback triggered when script has been appended to WKWebView
    func addEventListener(
        elementID: String,
        callbackID: String,
        elementType: ElementType,
        handler: WKScriptMessageHandler,
        completion: ((Error?) -> Void)? = nil
    ) {
        let element: String
        
        switch elementType {
        case .id:
            element = "document.getElementById('\(elementID)')"
        case .class:
            element = "document.getElementsByClassName('\(elementID)')[0]"
        }
        
        let scriptString = """
        function callback(event) {
            event.preventDefault();
            window.webkit.messageHandlers.\(callbackID).postMessage('\(elementID)');
        }
        
        \(element).addEventListener('click', callback);
        """
        
        DispatchQueue.main.async { [self] in
            if configuration.userContentController.userScripts.first(where: { $0.source == scriptString }) == nil {
                evaluateJavaScript(scriptString) { [weak self] _, error in
                    guard let self = self else { return }
                    
                    if let error {
                        completion?(error)
                        debugPrint(error)
                    } else {
                        self.configuration.userContentController.removeScriptMessageHandler(forName: callbackID)
                        self.configuration.userContentController.addUserScript(
                            WKUserScript(source: scriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
                        )
                        self.configuration.userContentController.add(handler, name: callbackID)
                    }
                }
            } else {
                completion?(InjectionError.listenerAlreadyAdded)
            }
        }
    }
}
