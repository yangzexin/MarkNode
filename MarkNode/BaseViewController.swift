//
//  BaseViewController.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
}

extension UIViewController {
    static func initFromNib() -> Self {
        let viewController = self.init(nibName: String(describing: self), bundle: nil)
        return viewController
    }
}
