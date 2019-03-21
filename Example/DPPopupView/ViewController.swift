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
        view.backgroundColor = .gray
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        view.backgroundColor = .white
    }
    
    fileprivate func setupViews() {
        view.addSubview(popupView)
    }
}
