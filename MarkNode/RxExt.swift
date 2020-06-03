//
//  DisposeBagExt.swift
//  demos
//
//  Created by yangzexin on 2020/5/28.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

extension NSObject {
    private struct AssociatedKeys {
        static var disposeBag = "_disposeBag"
    }
    
    var disposeBag: DisposeBag {
        get {
            if let obj = objc_getAssociatedObject(self, &AssociatedKeys.disposeBag) {
                return obj as! DisposeBag
            } else {
                let bag = DisposeBag()
                objc_setAssociatedObject(self, &AssociatedKeys.disposeBag, bag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return bag
            }
        }
    }
}

extension Reactive where Base: UIView {
    public var frame: Binder<CGRect> {
        return Binder(self.base) { view, frame in
            view.frame = frame
        }
    }
}
