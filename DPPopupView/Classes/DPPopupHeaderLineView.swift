//
//  DPPopupHeaderLineView.swift
//  DPPopupView
//
//  Created by Daniel Ma on 10/4/19.
//  Copyright © 2019 Daniel Ma. All rights reserved.
//

import UIKit

class DPPopupHeaderLineView: UIView {
    
    fileprivate let width: CGFloat = 30.0
    fileprivate let height: CGFloat = 4.0
    
    override var bounds: CGRect {
        didSet {
            if oldValue.width != bounds.width
                || oldValue.height != bounds.height {
                setNeedsLayout()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialization()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let path = UIBezierPath(roundedRect: CGRect(x: bounds.midX - width / 2,
                                                    y: bounds.midY - height / 2,
                                                    width: width,
                                                    height: height),
                                cornerRadius: height / 2)
        context.saveGState()
        context.addPath(path.cgPath)
        context.setFillColor(UIColor.lightGray.withAlphaComponent(0.7).cgColor)
        context.fillPath()
        context.restoreGState()
    }
}

extension DPPopupHeaderLineView {
    fileprivate func initialization() {
        backgroundColor = .clear
        setupViews()
    }
    
    fileprivate func setupViews() {
        
    }
}
