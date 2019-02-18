//
//  FullscreenPopGesture.swift
//  PopGesture
//
//  Created by Cobb on 2018/11/1.
//  Copyright © 2018 HK ONETHING TECHNOLOGIES LIMITED. All rights reserved.
//

import Foundation
import UIKit

open class FullscreenPopGesture {
    
    /// Configuration for PopGesture
    open class func configuration() {
        UINavigationController.navInitialize()
        UIViewController.controllerInitialize()
    }
}

/// objc_getAssociatedObject的key
private struct AssociatedObjectKey {
    
    static var willAppearInjectBlockContainer
        = "PopGesture.pointerKey.fuwillAppearInjectBlockContainer"
    
    static var interactivePopDisabled
        = "PopGesture.pointerKey.interactivePopDisabled"
    
    static var prefersNavigationBarHidden
        = "PopGesture.pointerKey.prefersNavigationBarHidden"
    
    static var maxAllowedInitialDistanceToLeftEdge
        = "PopGesture.pointerKey.maxAllowedInitialDistanceToLeftEdge"
    
    static var fullscreenPopGestureRecognizer
        = "PopGesture.pointerKey.fullscreenPopGestureRecognizer"
    
    static var popGestureRecognizerDelegate
        = "PopGesture.pointerKey.popGestureRecognizerDelegate"
    
    static var viewControllerBasedAppearanceEnabled
        = "PopGesture.pointerKey.viewControllerBasedAppearanceEnabled"
    
    static var scrollViewPopGestureRecognizerEnable
        = "PopGesture.pointerKey.scrollViewPopGestureRecognizerEnable"
}

typealias WillAppearInjectBlock = (_ viewController: UIViewController, _ animated: Bool) -> Void

private class WillAppearInjectBlockContainer {
    
    var block: WillAppearInjectBlock?
    
    init(_ block: @escaping WillAppearInjectBlock) {
        self.block = block
    }
}

class FullScreenPopGestureRecognizerDelegate: NSObject, UIGestureRecognizerDelegate {
    
    // MARK: - Property
    
    weak var navigationController: UINavigationController?
    
    // MARK: - Life Cycle
    
    override init() {
    }
    
    deinit {
        debugPrint("FullScreenPopGestureRecognizerDelegate")
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let navigationController = self.navigationController else {
            return false
        }
        
        // Ignore when no view controller is pushed into the navigation stack.
        guard navigationController.viewControllers.count > 1 else {
            return false
        }
        
        // Disable when the active view controller doesn't allow interactive pop.
        guard let topViewController = navigationController.viewControllers.last else {
            return false
        }
        guard !topViewController.interactivePopDisabled else {
            return false
        }
        
        // Ignore pan gesture when the navigation controller is currently in transition.
        guard let trasition = navigationController.value(forKey: "_isTransitioning") as? Bool else {
            return false
        }
        guard !trasition else {
            return false
        }
        
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        
        // Ignore when the beginning location is beyond max allowed initial distance to left edge.
        let beginningLocation = panGesture.location(in: panGesture.view)
        let maxAllowedInitialDistance = topViewController.maxAllowedInitialDistanceToLeftEdge
        guard maxAllowedInitialDistance <= 0 || CGFloat(beginningLocation.x) <= maxAllowedInitialDistance else {
            return false
        }
        
        // Prevent calling the handler when the gesture begins in an opposite direction.
        let translation = panGesture.translation(in: gestureRecognizer.view)
        let isLeftToRight = UIApplication.shared.userInterfaceLayoutDirection == .leftToRight
        let multiplier: CGFloat = isLeftToRight ? 1 : -1
        guard (translation.x * multiplier) > 0 else {
            return false
        }
        
        return true
    }
}

fileprivate extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    /**
     Executes a block of code, associated with a unique token, only once.  The code is thread safe and will
     only execute the code once even in the presence of multithreaded calls.
     
     - parameter token: A unique reverse DNS style name such as com.vectorform.<name> or a GUID
     - parameter block: Block to execute once
     */
    class func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        if _onceTracker.contains(token) {
            return
        }
        _onceTracker.append(token)
        block()
    }
}

/// allows any view controller to disable interactive pop gesture, which might
/// be necessary when the view controller itself handles pan gesture in some
/// cases.
extension UIViewController {
    
    // MARK: - Class Method
    
    open class func controllerInitialize() {
        DispatchQueue.once(token: "com.UIViewController.MethodSwizzling", block: {
            if let originalMethod = class_getInstanceMethod(self, #selector(viewWillAppear(_:))),
                let swizzledMethod = class_getInstanceMethod(self, #selector(swizzledViewWillAppear(_:))) {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        })
    }
    
    // MARK: - Property
    
    /// UIViewController willAppear Block
    fileprivate var willAppearBlockContainer: WillAppearInjectBlockContainer? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKey.willAppearInjectBlockContainer) as? WillAppearInjectBlockContainer
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKey.willAppearInjectBlockContainer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Whether the interactive pop gesture is disabled when contained in a navigation
    /// stack. default is false
    public var interactivePopDisabled: Bool {
        get {
            guard let bools = objc_getAssociatedObject(self, &AssociatedObjectKey.interactivePopDisabled) as? Bool else {
                return false
            }
            return bools
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKey.interactivePopDisabled, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// Indicate this view controller prefers its navigation bar hidden or not,
    /// checked when view controller based navigation bar's appearance is enabled.
    /// Default to NO, bars are more likely to show.
    public var prefersNavigationBarHidden: Bool {
        get {
            guard let bools = objc_getAssociatedObject(self, &AssociatedObjectKey.prefersNavigationBarHidden) as? Bool else {
                return false
            }
            return bools
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKey.prefersNavigationBarHidden, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// Max allowed initial distance to left edge when you begin the interactive pop
    /// gesture. 0 by default, which means it will ignore this limit.
    public var maxAllowedInitialDistanceToLeftEdge: CGFloat {
        get {
            guard let doubleNum = objc_getAssociatedObject(self, &AssociatedObjectKey.maxAllowedInitialDistanceToLeftEdge) as? Double else {
                return 0.0
            }
            return CGFloat(doubleNum)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKey.maxAllowedInitialDistanceToLeftEdge, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }
    
    // MARK: - Swizzeld
    
    @objc private func swizzledViewWillAppear(_ animated: Bool) {
        // Forward to primary implementation.
        self.swizzledViewWillAppear(animated)
        
        if let block = self.willAppearBlockContainer?.block {
            block(self, animated)
        }
    }
}

/// allows UINavigationController supporting fullscreen pan gesture.
/// Instead of screen edge, you can now swipe from any place on the screen and the onboard
/// interactive pop transition works seamlessly.
///
/// Adding the implementation file of this category to your target will
/// automatically patch UINavigationController with this feature.
extension UINavigationController {
    
    // MARK: - Class Method
    
    open class func navInitialize() {
        // Inject "-pushViewController:animated:"
        DispatchQueue.once(token: "com.UINavigationController.MethodSwizzling", block: {
            if let originalMethod = class_getInstanceMethod(self, #selector(pushViewController(_:animated:))),
                let swizzledMethod = class_getInstanceMethod(self, #selector(swizzledPushViewController(_:animated:))) {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        })
    }
    
    // MARK: - Property
    
    /// A view controller is able to control navigation bar's appearance by itself,
    /// rather than a global way, checking "fd_prefersNavigationBarHidden" property.
    /// Default to true, disable it if you don't want so.
    public var viewControllerBasedAppearanceEnabled: Bool {
        get {
            guard let enalbe = objc_getAssociatedObject(self, &AssociatedObjectKey.viewControllerBasedAppearanceEnabled) as? Bool else {
                self.viewControllerBasedAppearanceEnabled = true
                return true
            }
            return enalbe
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKey.viewControllerBasedAppearanceEnabled, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// The gesture recognizer that actually handles interactive pop.
    private var popGestureRecognizerDelegate: FullScreenPopGestureRecognizerDelegate {
        guard let delegate = objc_getAssociatedObject(self, &AssociatedObjectKey.popGestureRecognizerDelegate) as? FullScreenPopGestureRecognizerDelegate else {
            let popDelegate = FullScreenPopGestureRecognizerDelegate()
            popDelegate.navigationController = self
            objc_setAssociatedObject(self, &AssociatedObjectKey.popGestureRecognizerDelegate, popDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return popDelegate
        }
        return delegate
    }
    
    /// The gesture recognizer that actually handles interactive pop.
    private var fullscreenPopGestureRecognizer: UIPanGestureRecognizer {
        guard let pan = objc_getAssociatedObject(self, &AssociatedObjectKey.fullscreenPopGestureRecognizer) as? UIPanGestureRecognizer else {
            let panGesture = UIPanGestureRecognizer()
            panGesture.maximumNumberOfTouches = 1
            objc_setAssociatedObject(self, &AssociatedObjectKey.fullscreenPopGestureRecognizer, panGesture, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return panGesture
        }
        return pan
    }
    
    // MARK: - Private
    
    private func setupVCBasedNavBarAppearanceIfNeeded(_ appearingViewController: UIViewController) {
        if !viewControllerBasedAppearanceEnabled {
            return
        }
        
        let blockContainer = WillAppearInjectBlockContainer { [weak self] (_ viewController: UIViewController, _ animated: Bool) in
            self?.setNavigationBarHidden(viewController.prefersNavigationBarHidden, animated: animated)
        }
        
        // Setup will appear inject block to appearing view controller.
        // Setup disappearing view controller as well, because not every view controller is added into
        // stack by pushing, maybe by "-setViewControllers:".
        appearingViewController.willAppearBlockContainer = blockContainer
        if let viewController = viewControllers.last {
            if viewController.willAppearBlockContainer == nil {
                viewController.willAppearBlockContainer = blockContainer
            }
        }
    }
    
    // MARK: Swizzeld
    
    @objc private func swizzledPushViewController(_ viewController: UIViewController, animated: Bool) {
        if interactivePopGestureRecognizer?.view?.gestureRecognizers?.contains(fullscreenPopGestureRecognizer) == false {
            // Add our own gesture recognizer to where the onboard screen edge pan gesture recognizer is attached to.
            interactivePopGestureRecognizer?.view?.addGestureRecognizer(fullscreenPopGestureRecognizer)
            
            // Forward the gesture events to the private handler of the onboard gesture recognizer.
            let internalTargets = interactivePopGestureRecognizer?.value(forKey: "targets") as? [NSObject]
            let internalTarget = internalTargets?.first?.value(forKey: "target")
            let internalAction = NSSelectorFromString("handleNavigationTransition:")
            if let target = internalTarget {
                fullscreenPopGestureRecognizer.delegate = popGestureRecognizerDelegate
                fullscreenPopGestureRecognizer.addTarget(target, action: internalAction)
                
                // Disable the onboard gesture recognizer.
                interactivePopGestureRecognizer?.isEnabled = false
            }
        }
        
        // Handle perferred navigation bar appearance.
        setupVCBasedNavBarAppearanceIfNeeded(viewController)
        
        // Forward to primary implementation.
        self.swizzledPushViewController(viewController, animated: animated)
    }
}

extension UIScrollView: UIGestureRecognizerDelegate {
    
    /// ScrollView should response PopGesture, return true is enable.
    public var scrollViewPopGestureRecognizerEnable: Bool {
        get {
            guard let enable = objc_getAssociatedObject(self, &AssociatedObjectKey.scrollViewPopGestureRecognizerEnable) as? Bool else {
                return false
            }
            return enable
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKey.scrollViewPopGestureRecognizerEnable, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    /// UIGestureRecognizerDelegate
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if scrollViewPopGestureRecognizerEnable, self.contentOffset.x <= 0, let gestureDelegate = otherGestureRecognizer.delegate {
            if gestureDelegate.isKind(of: FullScreenPopGestureRecognizerDelegate.self) {
                return true
            }
        }
        return false
    }
}
