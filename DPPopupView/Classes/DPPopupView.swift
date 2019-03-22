//
//  DPPopupView.swift
//  DPPopupView
//
//  Created by Xueqiang Ma on 18/3/19.
//
//  Inspired by http://www.swiftkickmobile.com/building-better-app-animations-swift-uiviewpropertyanimator/ and https://developer.apple.com/videos/play/wwdc2017/230/
//

import UIKit

open class DPPopupView: UIView {
    enum State {
        case expanded
        case collapsed
        
        var opposite: State {
            switch self {
            case .expanded: return .collapsed
            case .collapsed: return .expanded
            }
        }
    }
    
    public let containerView = UIView()
    
    fileprivate let popupOffset: CGFloat = 340
    fileprivate let viewHeight: CGFloat = 500
    fileprivate var bottomConstraint: NSLayoutConstraint?
    fileprivate var currentState: State = .expanded
    fileprivate var progressWhenInterrupted: CGFloat = 0.0
    fileprivate var duration: TimeInterval = 1.0
    // Tracks all running animators
    var runningAnimators = [UIViewPropertyAnimator]()
    
    fileprivate let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        return view
    }()
    fileprivate lazy var tapGesture: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        return recognizer
    }()
    fileprivate lazy var panGesture: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        return recognizer
    }()
    
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
    }
}

// MARK: - Layouts
extension DPPopupView {
    fileprivate func initialization() {
        translatesAutoresizingMaskIntoConstraints = false
        setupViews()
        setupGestures()
    }
    
    fileprivate func setupViews() {
        addSubview(headerView)
        addSubview(containerView)
        headerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 20),
            // contianerView
            containerView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor)
            ])
    }
    
    fileprivate func setupBottomConstraint() {
        guard let superview = superview else { return }
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.trailingAnchor),
            heightAnchor.constraint(equalToConstant: viewHeight)
            ])
        bottomConstraint = bottomAnchor.constraint(equalTo: superview.safeAreaLayoutGuide.bottomAnchor, constant: 0.0)
        bottomConstraint?.isActive = true
    }
    
    fileprivate func setupGestures() {
        headerView.addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
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
            switch state {
            case .expanded:
                self.bottomConstraint?.constant = 0
            case .collapsed:
                self.bottomConstraint?.constant = self.popupOffset
            }
            self.superview?.layoutIfNeeded()
        }
        positionAnimator.addCompletion {(finalPosition) in
            switch finalPosition {
            case .start:
                self.currentState = state.opposite
            case .end:
                self.currentState = state
            case .current:
                break
            }
            // manually reset the constraint positions
            switch self.currentState {
            case .expanded:
                self.bottomConstraint?.constant = 0
            case .collapsed:
                self.bottomConstraint?.constant = self.popupOffset
            }
            self.runningAnimators.removeAll()
        }
        positionAnimator.startAnimation()
        runningAnimators.append(positionAnimator)
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
