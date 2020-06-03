//
//  DisplaySelectorView.swift
//  MarkNode
//
//  Created by yangzexin on 2020/6/2.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

@objc
protocol DisplaySelectorViewDelegate: NSObjectProtocol {
    @objc optional
    func didSelectLayout(displaySelectorView: DisplaySelectorView, layout: TSLayouterRegistry)
    @objc optional
    func didSelectStyle(displaySelectorView: DisplaySelectorView, style: TSMindViewStyleRegistry)
    @objc optional
    func didClose(displaySelectorView: DisplaySelectorView)
}

class DisplaySelectorView: SFIBCompatibleView {
    weak var delegate: DisplaySelectorViewDelegate?
    
    var uiRegistries: TSUIRegistriesType?
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var styleSelectView: StyleSelectorView!
    @IBOutlet var layoutSelectView: LayoutSelectorView!
    
    override func initCompat() {
        super.initCompat()
        self.sf_load(fromXibName: String(describing: DisplaySelectorView.self))
        
        self.backgroundView.sf_addTapListener { [weak self] _ in
            guard let self = self else { return }
            self.notifyDidClose()
        }
        self.styleSelectView.didSelectStyle = { [weak self] styleRegistry in
            guard let self = self else { return }
            if self.delegate?.responds(to: #selector(DisplaySelectorViewDelegate.didSelectStyle(displaySelectorView:style:))) ?? false {
                self.delegate?.didSelectStyle?(displaySelectorView: self, style: styleRegistry)
            }
            self.notifyDidClose()
        }
        self.layoutSelectView.didSelectStyle = { [weak self] layouterRegistry in
            guard let self = self else { return }
            if self.delegate?.responds(to: #selector(DisplaySelectorViewDelegate.didSelectLayout(displaySelectorView:layout:))) ?? false {
                self.delegate?.didSelectLayout?(displaySelectorView: self, layout: layouterRegistry)
            }
            self.notifyDidClose()
        }
    }
    
    private func notifyDidClose() {
        if self.delegate?.responds(to: #selector(DisplaySelectorViewDelegate.didClose(displaySelectorView:))) ?? false {
            self.delegate?.didClose!(displaySelectorView: self)
        }
    }
    
    @IBAction func segmentControlAction(target: UISegmentedControl) {
        let styleTabSelected = target.selectedSegmentIndex == 0
        self.styleSelectView.isHidden = !styleTabSelected
        self.layoutSelectView.isHidden = styleTabSelected
    }
    
    func show(visible: Bool, animated: Bool, completion: @escaping () -> Void) {
        if visible {
            self.styleSelectView.styleRegistries = uiRegistries?.allStyleRegistries()
            self.layoutSelectView.layoutRegistries = uiRegistries?.allLayoutRegistries()
        }
        
        let displayAlpha = 0.5
        let hiddenAlpha = 0.0
        self.backgroundView.alpha = CGFloat(visible ? hiddenAlpha : displayAlpha)
        
        let displayY = self.bounds.size.height - self.containerView.frame.size.height
        let hiddenY = self.bounds.size.height
        var frame = self.containerView.frame
        frame.origin.y = visible ? hiddenY : displayY
        self.containerView.frame = frame
        let animation: () -> Void = {
            self.backgroundView.alpha = CGFloat(visible ? displayAlpha : hiddenAlpha)
            var frame = self.containerView.frame
            frame.origin.y = visible ? displayY : hiddenY
            self.containerView.frame = frame
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: animation, completion: { _ in completion() })
        } else {
            animation()
        }
    }
}

extension DisplaySelectorView: HasDelegate {
    typealias Delegate = DisplaySelectorViewDelegate
}

class RxDisplaySelectorViewDelegateProxy: DelegateProxy<DisplaySelectorView, DisplaySelectorViewDelegate>, DelegateProxyType, DisplaySelectorViewDelegate {
    
    weak private(set) var displaySelectorView: DisplaySelectorView!
    
    init(_ displaySelectorView: ParentObject) {
        self.displaySelectorView = displaySelectorView
        super.init(parentObject: displaySelectorView, delegateProxy: RxDisplaySelectorViewDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        self.register { (displaySelectorView) -> RxDisplaySelectorViewDelegateProxy in
            RxDisplaySelectorViewDelegateProxy(displaySelectorView)
        }
    }
}

extension Reactive where Base: DisplaySelectorView {
    var delegate: DelegateProxy<DisplaySelectorView, DisplaySelectorViewDelegate> {
        return RxDisplaySelectorViewDelegateProxy.proxy(for: self.base)
    }
    
    var didClose: ControlEvent<Void> {
        return ControlEvent(events: delegate.methodInvoked(#selector(DisplaySelectorViewDelegate.didClose(displaySelectorView:))).map {_ in})
    }
    var didSelectStyle: ControlEvent<TSMindViewStyleRegistry> {
        return ControlEvent(events: delegate.methodInvoked(#selector(DisplaySelectorViewDelegate.didSelectStyle(displaySelectorView:style:))).map { args in
            args[1] as! TSMindViewStyleRegistry
        })
    }
    var didSelectLayout: ControlEvent<TSLayouterRegistry> {
        return ControlEvent(events: delegate.methodInvoked(#selector(DisplaySelectorViewDelegate.didSelectLayout(displaySelectorView:layout:))).map { args in
            args[1] as! TSLayouterRegistry
        })
    }
}
