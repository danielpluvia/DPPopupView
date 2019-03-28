//
//  ViewController.swift
//  DPPopupView
//
//  Created by danielpluvia on 03/18/2019.
//  Copyright (c) 2019 danielpluvia. All rights reserved.
//

import UIKit
import DPPopupView

class ViewController: UIViewController {
    fileprivate let popupView: DPPopupView = {
        let view = DPPopupView()
        view.containerView.backgroundColor = .yellow
        view.containerInset = .init(top: 20, left: 20, bottom: 20, right: 20)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        view.backgroundColor = .red
    }
    
    fileprivate func setupViews() {
        view.addSubview(popupView)
        
    }
}
