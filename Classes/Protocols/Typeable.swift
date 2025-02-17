#if os(macOS)
import AppKit
#else
import UIKit
#endif

public protocol Typeable {
    @discardableResult
    func typing(_ binding: State<Bool>) -> Self
    
    @discardableResult
    func typing(_ binding: State<Bool>, _ interval: TimeInterval) -> Self
}

protocol _Typeable: Typeable {
    func _setTypingInterval(_ v: TimeInterval)
    func _observeTypingState(_ v: State<Bool>)
}

@available(iOS 13.0, *)
extension Typeable {
    @discardableResult
    public func typing(_ binding: State<Bool>) -> Self {
        guard let s = self as? _Typeable else { return self }
        s._observeTypingState(binding)
        return self
    }
    
    @discardableResult
    public func typing(_ binding: UISwift.State<Bool>, _ interval: TimeInterval) -> Self {
        guard let s = self as? _Typeable else { return self }
        s._setTypingInterval(interval)
        return typing(binding)
    }
}

// for iOS lower than 13
extension _Typeable {
    @discardableResult
    public func typing(_ binding: State<Bool>) -> Self {
        _observeTypingState(binding)
        return self
    }
    
    @discardableResult
    public func typing(_ binding: UISwift.State<Bool>, _ interval: TimeInterval) -> Self {
        _setTypingInterval(interval)
        return typing(binding)
    }
}
