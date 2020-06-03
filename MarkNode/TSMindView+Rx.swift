//
//  TSMindView+Rx.swift
//  MarkNode
//
//  Created by yangzexin on 2020/6/3.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: TSMindView {
    public var style: Binder<TSMindViewStyle> {
        return Binder(self.base) { mindView, style in
            mindView.style = style
        }
    }
    
    public var layouter: Binder<TSLayouterProtocol> {
        return Binder(self.base) { mindView, layouter in
            mindView.layouter = layouter
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
    
    public var didUpdateSize: ControlEvent<TSUpdateSizeHandle> {
        return ControlEvent(events: delegate.methodInvoked(#selector(TSMindViewDelegate.mindView(_:didUpdateSize:))).map { args in args[1] as! TSUpdateSizeHandle })
    }
}
