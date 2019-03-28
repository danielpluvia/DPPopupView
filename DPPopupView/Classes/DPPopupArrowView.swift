//
//  DPPopupArrowView.swift
//  DPPopupView
//
//  Created by Xueqiang Ma on 28/3/19.
//

import UIKit

class DPPopupArrowView: UIView {
    fileprivate let arrowLength: CGFloat = 32.0
    fileprivate let arrowWidth: CGFloat = 2.0
    fileprivate let arrowColor: UIColor = .black
    fileprivate var yOffset: CGFloat = 0.0
    
    override var bounds: CGRect {
        didSet {
            yOffset = -bounds.height / 7.0
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
        let arrowPath = UIBezierPath()
        let point1 = CGPoint(x: bounds.midX - arrowLength / 2.0, y: bounds.midY + yOffset)
        let point2 = CGPoint(x: bounds.midX, y: bounds.maxY - 2 + yOffset)
        let point3 = CGPoint(x: bounds.midX + arrowLength / 2.0, y: bounds.midY + yOffset)
        arrowPath.move(to: point1)
        arrowPath.addLine(to: point2)
        arrowPath.addLine(to: point3)
        arrowPath.lineWidth = arrowWidth
        arrowPath.lineCapStyle = .round
        arrowPath.lineJoinStyle = .round
        arrowColor.setStroke()
        arrowPath.stroke()
    }
}

extension DPPopupArrowView {
    fileprivate func initialization() {
        contentMode = .redraw
        backgroundColor = .clear
        setupViews()
    }
    
    fileprivate func setupViews() {
        
    }
}
