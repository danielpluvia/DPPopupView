//
//  DPPopupView.swift
//  DPPopupView
//
//  Created by Xueqiang Ma on 18/3/19.
//
//  Inspired by
//  http://www.swiftkickmobile.com/building-better-app-animations-swift-uiviewpropertyanimator/
//  and https://developer.apple.com/videos/play/wwdc2017/230/
//  and https://www.youtube.com/watch?v=Yrb78U3V16g&t=601s
//

import UIKit

public protocol DPPopupViewDelegate {
    
}

// MARK: - Public methods
public extension DPPopupView {
    
}

open class DPPopupView: UIView {
    public enum State: Int, CaseIterable {
        case expandedMax = 0
        case expandedMin = 1
        case collapsedMax = 2
        case collapsedMin = 3
        
        func pre() -> State {
            let allStates = type(of: self).allCases
            return allStates[(allStates.firstIndex(of: self)! - 1) % allStates.count]
        }
        
        func next() -> State {
            let allStates = type(of: self).allCases
            return allStates[(allStates.firstIndex(of: self)! + 1) % allStates.count]
        }
    }
    
    // MARK: Public variables
    public let containerView = UIView()
    open var delegate: DPPopupViewDelegate?
    open var duration: TimeInterval = 1.0
    open var cornerRadius: CGFloat = 10.0
    open var containerInset: UIEdgeInsets = .zero {
        // Change the container layout's constraints according to the inset value
        didSet {
            if oldValue.top != containerInset.top {
                containerTopConstraint?.constant = containerInset.top
            }
            if oldValue.left != containerInset.left {
                containerLeadingConstraint?.constant = containerInset.left
            }
            if oldValue.bottom != containerInset.bottom {
                containerBottomConstraint?.constant = -containerInset.bottom
            }
            if oldValue.right != containerInset.right {
                containerTrailingConstraint?.constant = -containerInset.right
            }
        }
    }
    public let headerView: UIView = {
        let view = DPPopupHeaderLineView()
        return view
    }()
    
    // MARK: Private variables
    fileprivate var currentState: State = .expandedMax  // current state (before animation completing)
    fileprivate var toState: State = .expandedMin       // the state that is animated to
    // Size
    fileprivate var maxOffset: CGFloat {
        get {
            return CGFloat(bounds.height - headerHeight)
        }
    }
    fileprivate let headerHeight: CGFloat = 30
    // Tracks all running animators
    fileprivate var runningAnimators = [UIViewPropertyAnimator]()
    fileprivate var progressWhenInterrupted: CGFloat = 0.0
    fileprivate var offsetWhenInterrupted: CGFloat = 0.0
    // the container's Constraints
    fileprivate var containerTopConstraint: NSLayoutConstraint?
    fileprivate var containerLeadingConstraint: NSLayoutConstraint?
    fileprivate var containerBottomConstraint: NSLayoutConstraint?
    fileprivate var containerTrailingConstraint: NSLayoutConstraint?
    // Gestures
    fileprivate lazy var tapGesture: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        return recognizer
    }()
    fileprivate lazy var panGesture: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        return recognizer
    }()
    
    open override var bounds: CGRect {
        didSet {
            if bounds.width != oldValue.width
                || bounds.height != oldValue.height {
                setShadow()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        setupBottomConstraint()
        setFinalUI(accordingTo: currentState)
    }
}

// MARK: - Layouts
extension DPPopupView {
    fileprivate func initialization() {
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
        // masked corners: only top
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        setupViews()
        setupGestures()
        setShadow()
    }
    
    fileprivate func setupViews() {
        addSubview(headerView)
        addSubview(containerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        // Header View
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: headerHeight),
            ])
        // Container View
        containerTopConstraint = containerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: containerInset.top)
        containerLeadingConstraint = containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: containerInset.left)
        containerBottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -containerInset.bottom)
        containerTrailingConstraint = containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -containerInset.right)
        containerTopConstraint?.isActive = true
        containerLeadingConstraint?.isActive = true
        containerBottomConstraint?.isActive = true
        containerTrailingConstraint?.isActive = true
    }
    
    fileprivate func setupBottomConstraint() {
        guard let superview = superview else { return }
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.topAnchor),
            leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor),
            bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor),
            trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor)
            ])
    }
    
    fileprivate func setupGestures() {
        headerView.addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
    }
    
    fileprivate func setShadow() {
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowRadius = 6.0
        layer.shadowOpacity = 0.3
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
    }
}

// MARK: - Gestures
extension DPPopupView {
    @objc fileprivate func handleTap(recognizer: UITapGestureRecognizer) {
        animateOrReverseRunningTransition(state: toState, duration: duration)
    }
    
    @objc fileprivate func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            runningAnimators.forEach { (animator) in
                animator.stopAnimation(true)
            }
            runningAnimators.removeAll()
            offsetWhenInterrupted = transform.ty
        case .changed:
            let translation = recognizer.translation(in: self)
            var yOffset = offsetWhenInterrupted + translation.y
            yOffset = min(yOffset, maxOffset)
            yOffset = max(yOffset, 0)
            transform = CGAffineTransform(translationX: 0, y: yOffset)
        case .ended:
            let translation = recognizer.translation(in: self)
            var yOffset = offsetWhenInterrupted + translation.y
            yOffset = min(yOffset, maxOffset)
            yOffset = max(yOffset, 0)
            let states = nearestStates(for: yOffset)
            let yVelocity = recognizer.velocity(in: self).y
            if yVelocity == 0 || abs(yVelocity) < 1 {
                break
            } else if yVelocity > 0 {
                animateOrReverseRunningTransition(state: states[1], duration: duration / 3)
            } else if yVelocity < 0 {
                animateOrReverseRunningTransition(state: states[0], duration: duration / 3)
            }
        default:
            break
        }
    }
}

extension DPPopupView {
    // Perform all animations with animators if not already running
    fileprivate func animateTransitionIfNeeded(state: State, duration: TimeInterval) {
        guard runningAnimators.isEmpty else { return }
        // Frame
        let positionAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1.0) {
            self.setFinalUI(accordingTo: state)
        }
        positionAnimator.addCompletion {(finalPosition) in
            switch finalPosition {
            case .start:
                self.currentState = state.next()
            case .end:
                self.currentState = state
                self.toState = state.next()
            case .current:
                break
            @unknown default:
                fatalError("@unknown default");
            }
            self.runningAnimators.removeAll()
        }
        positionAnimator.startAnimation()
        runningAnimators.append(positionAnimator)
    }
    
    fileprivate func setFinalUI(accordingTo state: State) {
        switch state {
        case .expandedMax:
            transform = .identity
            layer.cornerRadius = 0
        case .expandedMin, .collapsedMax, .collapsedMin:
            transform = CGAffineTransform(translationX: 0, y: offset(for: state))
            layer.cornerRadius = cornerRadius
        }
        self.superview?.layoutIfNeeded()
    }
    
    /// Calculate the offset of a specific state.
    fileprivate func offset(for state: State) -> CGFloat {
        var offset: CGFloat = 0
        switch state {
        case .expandedMax:
            offset = 0
        case .expandedMin:
            offset = maxOffset / 3
        case .collapsedMax:
            offset = maxOffset / 3 * 2
        case .collapsedMin:
            offset = maxOffset
        }
        return offset
    }
    
    /// Calculate the state of a specific offset.
    fileprivate func nearestStates(for offset: CGFloat) -> [State] {
        var states: [State] = []
        let expandedMaxOffset = self.offset(for: .expandedMax)
        let expandedMinOffset = self.offset(for: .expandedMin)
        let collapsedMaxOffset = self.offset(for: .collapsedMax)
        let collapsedMinOffset = self.offset(for: .collapsedMin)
        if offset >= expandedMaxOffset && offset < expandedMinOffset {
            return [.expandedMax, .expandedMin]
        } else if offset >= expandedMinOffset && offset < collapsedMaxOffset {
            return [.expandedMin, .collapsedMax]
        } else if offset >= collapsedMaxOffset && offset < collapsedMinOffset {
            return [.collapsedMax, .collapsedMin]
        }
        return states
    }
    
    /// Starts transition if necessary or reverses it on tap
    fileprivate func animateOrReverseRunningTransition(state: State, duration: TimeInterval) {
        if runningAnimators.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        } else {
            runningAnimators.forEach { (animator) in
                animator.isReversed = !animator.isReversed
            }
        }
    }
    
    // Starts transition if necessary and pauses on pan .begin
    fileprivate func startInteractiveTransition(state: State, duration: TimeInterval) {
        animateTransitionIfNeeded(state: state, duration: duration)
        runningAnimators.forEach { (animator) in
            animator.pauseAnimation()
        }
        if let firstAnimator = runningAnimators.first {
            progressWhenInterrupted = firstAnimator.fractionComplete
        }
    }
    
    // Scrubs transition on pan .changed
    fileprivate func updateInteractiveTransition(fractionComplete: CGFloat) {
        runningAnimators.forEach { (animator) in
            animator.fractionComplete = fractionComplete
        }
    }
    
    // Continues or reverse transition on pan .ended
    fileprivate func continueInteractiveTransition() {
        runningAnimators.forEach { (animator) in
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0.0)
        }
    }
}
