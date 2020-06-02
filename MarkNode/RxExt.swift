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

extension TSMindView: HasDelegate {
    public typealias Delegate = TSMindViewDelegate
}

open class RxMindViewDelegateProxy: DelegateProxy<TSMindView, TSMindViewDelegate>, DelegateProxyType, TSMindViewDelegate {
    weak private(set) var mindView: TSMindView!
    
    init(_ mindView: ParentObject) {
        self.mindView = mindView
        super.init(parentObject: mindView, delegateProxy: RxMindViewDelegateProxy.self)
    }
    
    public static func registerKnownImplementations() {
        self.register { (mindView) -> RxMindViewDelegateProxy in
            RxMindViewDelegateProxy(mindView)
        }
    }
}

extension Reactive where Base: TSMindView {
    public var delegate: DelegateProxy<TSMindView, TSMindViewDelegate> {
        return RxMindViewDelegateProxy.proxy(for: self.base)
    }
    
    public var itemSelected: ControlEvent<TSMindNodeView?> {
        let source = delegate.methodInvoked(#selector(TSMindViewDelegate.mindView(_:didSelect:)))
            .map { args in
                return args[1] as? TSMindNodeView
        }
        return ControlEvent(events: source)
    }
    
    public var finishLayout: ControlEvent<Void> {
        let source = delegate.methodInvoked(#selector(TSMindViewDelegate.didFinishLayoutMindView(_:)))
            .map { _ in }
        
        return ControlEvent(events: source)
    }
}

extension Reactive where Base: UIView {
    public var frame: Binder<CGRect> {
        return Binder(self.base) { view, frame in
            view.frame = frame
        }
    }
}
