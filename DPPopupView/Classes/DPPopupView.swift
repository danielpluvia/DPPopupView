//
//  DPPopupView.swift
//  DPPopupView
//
//  Created by Xueqiang Ma on 18/3/19.
//
//  Inspired by http://www.swiftkickmobile.com/building-better-app-animations-swift-uiviewpropertyanimator/ and https://developer.apple.com/videos/play/wwdc2017/230/
//

import UIKit

public protocol DPPopupViewDelegate {
    
}

// MARK: - Public methods
public extension DPPopupView {
    func update(state: State) {
        animateTransitionIfNeeded(state: .expanded, duration: 1.0)
    }
}

open class DPPopupView: UIView {
    public enum State {
        case expanded
        case collapsed
        //        case minimum
        
        var opposite: State {
            switch self {
            case .expanded: return .collapsed
            case .collapsed: return .expanded
                //            case .minimum: return .collapsed
            }
        }
    }
    
    // MARK: Public variables
    public let containerView = UIView()
    open var delegate: DPPopupViewDelegate?
    open var duration: TimeInterval = 1.0
    open var popupOffset: CGFloat = 340
    open var viewHeight: CGFloat = 500
    open var cornerRadius: CGFloat = 10.0
    open var containerInset: UIEdgeInsets = .zero {
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
    fileprivate var currentState: State = .expanded
    // Tracks all running animators
    fileprivate var runningAnimators = [UIViewPropertyAnimator]()
    fileprivate var progressWhenInterrupted: CGFloat = 0.0
    // AutoLayout Constraints
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
            headerView.heightAnchor.constraint(equalToConstant: 30),
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
            leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor),
            bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: 0.0),
            trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor),
            heightAnchor.constraint(equalToConstant: viewHeight)
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
        animateOrReverseRunningTransition(state: currentState.opposite, duration: duration)
    }
    
    @objc fileprivate func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: currentState.opposite, duration: duration)
        case .changed:
            let translation = recognizer.translation(in: self)
            var progress = translation.y / popupOffset
            if currentState == .collapsed { progress *= -1 }
            if !runningAnimators.isEmpty && runningAnimators[0].isReversed { progress *= -1 }
            progress += progressWhenInterrupted
            updateInteractiveTransition(fractionComplete: progress)
        case .ended:    // https://www.youtube.com/watch?v=Yrb78U3V16g&t=601s
            let yVelocity = recognizer.velocity(in: self).y
            if yVelocity == 0 {
                continueInteractiveTransition()
                break
            }
            let shouldExpand = yVelocity < 0
            switch currentState {
            case .expanded:
                if (shouldExpand && !runningAnimators.isEmpty && !runningAnimators[0].isReversed) || (!shouldExpand && !runningAnimators.isEmpty && runningAnimators[0].isReversed) {
                    runningAnimators.forEach{ $0.isReversed = !$0.isReversed }
                }
            case .collapsed:
                if (!shouldExpand && !runningAnimators.isEmpty && !runningAnimators[0].isReversed) || (shouldExpand && !runningAnimators.isEmpty && runningAnimators[0].isReversed) {
                    runningAnimators.forEach{ $0.isReversed = !$0.isReversed }
                }
            }
            continueInteractiveTransition()
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
                self.currentState = state.opposite
            case .end:
                self.currentState = state
            case .current:
                break
            @unknown default:
                fatalError("@unknown default");
            }
            //            // manually reset the constraint positions
            //            switch self.currentState {
            //            case .expanded:
            //                self.bottomConstraint?.constant = 0
            //            case .collapsed:
            //                self.bottomConstraint?.constant = self.popupOffset
            //            }
            self.runningAnimators.removeAll()
        }
        positionAnimator.startAnimation()
        runningAnimators.append(positionAnimator)
    }
    
    fileprivate func setFinalUI(accordingTo state: State) {
        switch state {
        case .expanded:
            //            bottomConstraint?.constant = 0
            transform = .identity
            layer.cornerRadius = cornerRadius
        case .collapsed:
            //            bottomConstraint?.constant = popupOffset
            transform = CGAffineTransform(translationX: 0, y: popupOffset)
            layer.cornerRadius = 0
        }
        self.superview?.layoutIfNeeded()
    }
    
    // Starts transition if necessary or reverses it on tap
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
