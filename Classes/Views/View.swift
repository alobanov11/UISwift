#if os(macOS)
import AppKit
#else
import UIKit
#endif

open class UView: BaseView, UIViewable, AnyDeclarativeProtocol, DeclarativeProtocolInternal {
    public var declarativeView: UView { self }
    public lazy var properties = Properties<UView>()
    lazy var _properties = PropertiesInternal()
    
    @State public var height: CGFloat = 0
    @State public var width: CGFloat = 0
    @State public var top: CGFloat = 0
    @State public var leading: CGFloat = 0
    @State public var left: CGFloat = 0
    @State public var trailing: CGFloat = 0
    @State public var right: CGFloat = 0
    @State public var bottom: CGFloat = 0
    @State public var centerX: CGFloat = 0
    @State public var centerY: CGFloat = 0
	@State public var isShimmering = false
    
    var __height: State<CGFloat> { _height }
    var __width: State<CGFloat> { _width }
    var __top: State<CGFloat> { _top }
    var __leading: State<CGFloat> { _leading }
    var __left: State<CGFloat> { _left }
    var __trailing: State<CGFloat> { _trailing }
    var __right: State<CGFloat> { _right }
    var __bottom: State<CGFloat> { _bottom }
    var __centerX: State<CGFloat> { _centerX }
    var __centerY: State<CGFloat> { _centerY }

	var shimmeringConfig = UShimmeringConfig.default
    
    open override var tag: Int {
        get { properties.tag }
        set {
            #if !os(macOS)
            super.tag = newValue
            #endif
            properties.tag = newValue
        }
    }
    
    public init (@BodyBuilder block: BodyBuilder.SingleView) {
        super.init(frame: .zero)
        _setup()
        body { block() }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        _setup()
    }
    
    public convenience init () {
        self.init(frame: .zero)
    }
    
    private func _setup() {
        translatesAutoresizingMaskIntoConstraints = false
        body { body }
        buildView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @BodyBuilder open var body: BodyBuilder.Result { EmptyBodyBuilderItem() }

    #if os(macOS)
    open override func layout() {
        super.layout()
        onLayoutSubviews()
    }
    
    open override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        movedToSuperview()
    }
    
    @discardableResult
    open override func resignFirstResponder() -> Bool {
        window?.makeFirstResponder(nil)
        return super.resignFirstResponder()
    }
    #else
    open override func layoutSubviews() {
        super.layoutSubviews()
        onLayoutSubviews()
		if self.isShimmering {
			self.stopShimmering()
			self.startShimmering()
		}
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        movedToSuperview()
    }
    #endif
    
    open func buildView() {
		$isShimmering.listen { [weak self] in
			if $0 {
				self?.startShimmering()
			}
			else {
				self?.stopShimmering()
			}
		}
	}
    
    // MARK: Touches
    #if os(macOS)
    typealias TouchClosure = (NSEvent) -> Void
    #else
    typealias TouchClosure = (Set<UITouch>, UIEvent?) -> Void
    #endif
    
    var _touchesBegan: TouchClosure?
    var _touchesMoved: TouchClosure?
    var _touchesEnded: TouchClosure?
    var _touchesCancelled: TouchClosure?
    
    #if os(macOS)
    open override func touchesBegan(with event: NSEvent) {
        super.touchesBegan(with: event)
        gestureRecognizers.forEach {
            ($0 as? USwipeGestureRecognizer)?.touchesBegan(with: event)
        }
        _touchesBegan?(event)
    }
    
    open override func touchesMoved(with event: NSEvent) {
        super.touchesMoved(with: event)
        gestureRecognizers.forEach {
            ($0 as? USwipeGestureRecognizer)?.touchesMoved(with: event)
        }
        _touchesMoved?(event)
    }
    
    open override func touchesEnded(with event: NSEvent) {
        super.touchesEnded(with: event)
        gestureRecognizers.forEach {
            ($0 as? USwipeGestureRecognizer)?.touchesEnded(with: event)
        }
        _touchesEnded?(event)
    }
    
    open override func touchesCancelled(with event: NSEvent) {
        super.touchesCancelled(with: event)
        gestureRecognizers.forEach {
            ($0 as? USwipeGestureRecognizer)?.touchesCancelled(with: event)
        }
        _touchesCancelled?(event)
    }
    
    public enum TouchPanState: CustomStringConvertible {
        case began, changed, ended, cancelled, swiped
        
        public var description: String {
            switch self {
            case .began: return "began"
            case .changed: return "changed"
            case .ended: return "ended"
            case .cancelled: return "cancelled"
            case .swiped: return "swiped"
            }
        }
    }
    
    public typealias TouchPanHandler = (TouchPanState, CGPoint, CGPoint) -> Void
    
    var _touchPanHandler: TouchPanHandler?
    var scrollBeganPoint: CGPoint?
    var scrollLastDeltaPoint: CGPoint = .zero
    
    open override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        switch event.phase {
        case .began:
            scrollBeganPoint = .init(x: event.scrollingDeltaX, y: event.scrollingDeltaY)
            scrollLastDeltaPoint = scrollBeganPoint ?? .zero
            _touchPanHandler?(.began, .zero, .zero)
        case .changed:
            if let scrollBeganPoint = scrollBeganPoint {
                scrollLastDeltaPoint.x += event.scrollingDeltaX
                scrollLastDeltaPoint.y += event.scrollingDeltaY
                _touchPanHandler?(.changed, scrollLastDeltaPoint, .init(x: event.deltaX, y: event.deltaY))
            }
        case .ended:
            if let scrollBeganPoint = scrollBeganPoint {
                scrollLastDeltaPoint.x += event.scrollingDeltaX
                scrollLastDeltaPoint.y += event.scrollingDeltaY
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { [weak self] in
                    guard let self = self else { return }
                    if let _ = self.scrollBeganPoint {
                        self._touchPanHandler?(.ended, self.scrollLastDeltaPoint, .init(x: event.deltaX, y: event.deltaY))
                    }
                }
            }
        case .cancelled:
            if let scrollBeganPoint = scrollBeganPoint {
                _touchPanHandler?(.cancelled, .zero, .zero)
                self.scrollBeganPoint = nil
            }
        case .mayBegin:
            break
        case .stationary:
            break
        default:
            if let scrollBeganPoint = scrollBeganPoint {
                print(event)
                scrollLastDeltaPoint.x += event.scrollingDeltaX
                scrollLastDeltaPoint.y += event.scrollingDeltaY
                _touchPanHandler?(.swiped, scrollLastDeltaPoint, .init(x: event.deltaX, y: event.deltaY))
                self.scrollBeganPoint = nil
            }
        }
    }
    
    /// Touch pan gesture handler
    /// to handle touch pan on magic mouse with one finger
    /// and on magic trackpad with two fingers
    ///
    /// Parameters:
    /// - state
    /// - scrollDelta: scroll position
    /// - delta: to understand the way of moving (especially for swipe state)
    @discardableResult
    public func onTouchPanGesture(_ action: @escaping TouchPanHandler) -> Self {
        _touchPanHandler = action
        return self
    }
    #else
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        _touchesBegan?(touches, event)
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        _touchesMoved?(touches, event)
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        _touchesEnded?(touches, event)
    }
    
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        _touchesCancelled?(touches, event)
    }
    #endif
}

// MARK: - Shimmering

extension UView {
	@discardableResult
	public func shimmering(_ value: State<Bool>, _ config: UShimmeringConfig = .default) -> Self {
		value.listen { [weak self] in self?.shimmering($0, config) }
		return self.shimmering(value.wrappedValue, config)
	}

	@discardableResult
	public func shimmering(_ value: Bool, _ config: UShimmeringConfig = .default) -> Self {
		self.shimmeringConfig = config
		self.isShimmering = value
		return self
	}

	func startShimmering() {
		let gradientLayer = CAGradientLayer()
		gradientLayer.name = "shimmeringLayer"
		gradientLayer.frame = self.bounds
		gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
		gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
		gradientLayer.colors = self.shimmeringConfig.colors.map { $0.cgColor }
		gradientLayer.locations = [0.0, 0.5, 1.0]
		self.layer.addSublayer(gradientLayer)

		let animation = CABasicAnimation(keyPath: "locations")
		animation.fromValue = [-1.0, -0.5, 0.0]
		animation.toValue = [1.0, 1.5, 2.0]
		animation.repeatCount = .infinity
		animation.duration = self.shimmeringConfig.duration

		gradientLayer.add(animation, forKey: animation.keyPath)
	}

	func stopShimmering() {
		let gradientLayer = self.layer.sublayers?.first { $0.name == "shimmeringLayer" }
		UIView.animate(withDuration: 1, animations: {
			gradientLayer?.opacity = 0
		}, completion: { _ in
			gradientLayer?.removeFromSuperlayer()
		})
	}
}

// MARK: Convenience Initializers

extension UView {
    public static func inline(_ v: () -> BaseView) -> UView {
        .init(inline: v())
    }
    
    public convenience init (_ innerView: BaseView) {
        self.init()
        body { innerView }
    }
    
    public convenience init (inline inlineView: BaseView) {
        self.init()
        inlineView.translatesAutoresizingMaskIntoConstraints = false
        body { inlineView }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: inlineView.leadingAnchor),
            trailingAnchor.constraint(equalTo: inlineView.trailingAnchor),
            topAnchor.constraint(equalTo: inlineView.topAnchor),
            bottomAnchor.constraint(equalTo: inlineView.bottomAnchor)
        ])
    }
    
    public convenience init <V>(_ innerView: () -> V) where V: DeclarativeProtocol {
        self.init()
        body { innerView().declarativeView }
    }
    
    @discardableResult
    public func subviews(@BodyBuilder block: BodyBuilder.SingleView) -> Self {
        body { block() }
    }
    
    public static func subviews(@BodyBuilder block: BodyBuilder.SingleView) -> UView {
        UView(block: block)
    }
}

// MARK: Touches
#if os(macOS)
extension UView {
    /// Began
    @discardableResult
    public func touchesBegan(_ closure: @escaping () -> Void) -> Self {
        _touchesBegan = { _ in closure() }
        return self
    }
    
    @discardableResult
    public func touchesBegan(_ closure: @escaping (Self) -> Void) -> Self {
        _touchesBegan = { _ in closure(self) }
        return self
    }
    
    @discardableResult
    public func touchesBegan(_ closure: @escaping (Self, NSEvent) -> Void) -> Self {
        _touchesBegan = { closure(self, $0) }
        return self
    }
    
    /// Moved
    @discardableResult
    public func touchesMoved(_ closure: @escaping () -> Void) -> Self {
        _touchesMoved = { _ in closure() }
        return self
    }
    
    @discardableResult
    public func touchesMoved(_ closure: @escaping (Self) -> Void) -> Self {
        _touchesMoved = { _ in closure(self) }
        return self
    }
    
    @discardableResult
    public func touchesMoved(_ closure: @escaping (Self, NSEvent) -> Void) -> Self {
        _touchesMoved = { closure(self, $0) }
        return self
    }
    
    /// Ended
    @discardableResult
    public func touchesEnded(_ closure: @escaping () -> Void) -> Self {
        _touchesEnded = { _ in closure() }
        return self
    }
    
    @discardableResult
    public func touchesEnded(_ closure: @escaping (Self) -> Void) -> Self {
        _touchesEnded = { _ in closure(self) }
        return self
    }
    
    @discardableResult
    public func touchesEnded(_ closure: @escaping (Self, NSEvent) -> Void) -> Self {
        _touchesEnded = { closure(self, $0) }
        return self
    }
    
    /// Cancelled
    @discardableResult
    public func touchesCancelled(_ closure: @escaping () -> Void) -> Self {
        _touchesCancelled = { _ in closure() }
        return self
    }
    
    @discardableResult
    public func touchesCancelled(_ closure: @escaping (Self) -> Void) -> Self {
        _touchesCancelled = { _ in closure(self) }
        return self
    }
    
    @discardableResult
    public func touchesCancelled(_ closure: @escaping (Self, NSEvent) -> Void) -> Self {
        _touchesCancelled = { closure(self, $0) }
        return self
    }
}
#else
extension UView {
    /// Began
    @discardableResult
    public func touchesBegan(_ closure: @escaping () -> Void) -> Self {
        _touchesBegan = { _,_ in closure() }
        return self
    }
    
    @discardableResult
    public func touchesBegan(_ closure: @escaping (Self) -> Void) -> Self {
        _touchesBegan = { _,_ in closure(self) }
        return self
    }
    
    @discardableResult
    public func touchesBegan(_ closure: @escaping (Self, Set<UITouch>) -> Void) -> Self {
        _touchesBegan = { set, _ in
            closure(self, set)
        }
        return self
    }
    
    @discardableResult
    public func touchesBegan(_ closure: @escaping (Self, Set<UITouch>, UIEvent?) -> Void) -> Self {
        _touchesBegan = { set, event in
            closure(self, set, event)
        }
        return self
    }
    
    /// Moved
    @discardableResult
    public func touchesMoved(_ closure: @escaping () -> Void) -> Self {
        _touchesMoved = { _,_ in closure() }
        return self
    }
    
    @discardableResult
    public func touchesMoved(_ closure: @escaping (Self) -> Void) -> Self {
        _touchesMoved = { _,_ in closure(self) }
        return self
    }
    
    @discardableResult
    public func touchesMoved(_ closure: @escaping (Self, Set<UITouch>) -> Void) -> Self {
        _touchesMoved = { set, _ in
            closure(self, set)
        }
        return self
    }
    
    @discardableResult
    public func touchesMoved(_ closure: @escaping (Self, Set<UITouch>, UIEvent?) -> Void) -> Self {
        _touchesMoved = { set, event in
            closure(self, set, event)
        }
        return self
    }
    
    /// Ended
    @discardableResult
    public func touchesEnded(_ closure: @escaping () -> Void) -> Self {
        _touchesEnded = { _,_ in closure() }
        return self
    }
    
    @discardableResult
    public func touchesEnded(_ closure: @escaping (Self) -> Void) -> Self {
        _touchesEnded = { _,_ in closure(self) }
        return self
    }
    
    @discardableResult
    public func touchesEnded(_ closure: @escaping (Self, Set<UITouch>) -> Void) -> Self {
        _touchesEnded = { set, _ in
            closure(self, set)
        }
        return self
    }
    
    @discardableResult
    public func touchesEnded(_ closure: @escaping (Self, Set<UITouch>, UIEvent?) -> Void) -> Self {
        _touchesEnded = { set, event in
            closure(self, set, event)
        }
        return self
    }
    
    /// Cancelled
    @discardableResult
    public func touchesCancelled(_ closure: @escaping () -> Void) -> Self {
        _touchesCancelled = { _,_ in closure() }
        return self
    }
    
    @discardableResult
    public func touchesCancelled(_ closure: @escaping (Self) -> Void) -> Self {
        _touchesCancelled = { _,_ in closure(self) }
        return self
    }
    
    @discardableResult
    public func touchesCancelled(_ closure: @escaping (Self, Set<UITouch>) -> Void) -> Self {
        _touchesCancelled = { set, _ in
            closure(self, set)
        }
        return self
    }
    
    @discardableResult
    public func touchesCancelled(_ closure: @escaping (Self, Set<UITouch>, UIEvent?) -> Void) -> Self {
        _touchesCancelled = { set, event in
            closure(self, set, event)
        }
        return self
    }
}
#endif
