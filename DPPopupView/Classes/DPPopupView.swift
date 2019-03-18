//
//  DPPopupView.swift
//  DPPopupView
//
//  Created by Xueqiang Ma on 18/3/19.
//

import UIKit

open class DPPopupView: UIView {
    enum State {
        case open
        case closed
        
        var opposite: State {
            switch self {
            case .open: return .closed
            case .closed: return .open
            }
        }
    }
    
    fileprivate let popupOffset: CGFloat = 440
    fileprivate let viewHeight: CGFloat = 500
    fileprivate var bottomConstraint: NSLayoutConstraint?
    
    fileprivate lazy var tapGesture: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(recognizer:)))
        return recognizer
    }()
    fileprivate lazy var panGesture: UIPanGestureRecognizer = {
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan(recognizer:)))
        return recognizer
    }()
    fileprivate lazy var stateAnimator: UIViewPropertyAnimator = {
        let animator = UIViewPropertyAnimator(duration: 1.0, dampingRatio: 1.0, animations: {
            self.bottomConstraint?.constant = self.popupOffset
            self.superview?.layoutIfNeeded()
        })
        animator.startAnimation()
        animator.pauseAnimation()
        animator.pausesOnCompletion = true
        animator.isReversed = true
        return animator
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
        addGestureRecognizer(tapGesture)
        addGestureRecognizer(panGesture)
    }
}

// MARK: - Gestures
extension DPPopupView {
    @objc fileprivate func didTap(recognizer: UITapGestureRecognizer) {
        stateAnimator.isReversed = !stateAnimator.isReversed
        stateAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
    
    @objc fileprivate func didPan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            stateAnimator.pauseAnimation()
            stateAnimator.isReversed = !stateAnimator.isReversed
        case .changed:
            let translation = recognizer.translation(in: self)
            var fraction = -translation.y / popupOffset
            if !stateAnimator.isReversed { fraction *= -1 }
            print(fraction)
            stateAnimator.fractionComplete = fraction
        case .ended:
            // variable setup
            let yVelocity = recognizer.velocity(in: self).y
            let shouldClose = yVelocity > 0
            
            // if there is no motion, continue all animations and exit early
            if yVelocity == 0 {
                stateAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                break
            }
            
            // reverse the animations based on their current state and pan motion
            if shouldClose {
                stateAnimator.isReversed = false
            } else {
                stateAnimator.isReversed = true
            }
            stateAnimator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        default:
            break
        }
    }
}
