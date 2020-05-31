//
//  SceneTransitionType.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import UIKit
import RxSwift

protocol SceneCoordinatorType {
    init(window: UIWindow)
    
    @discardableResult func transition(to scene: TargetScene) -> Observable<Void>
    @discardableResult func pop(animated: Bool) -> Observable<Void>
}

class SceneCoordinator: NSObject, SceneCoordinatorType {
    static var shared: SceneCoordinator!
    
    fileprivate var window: UIWindow
    
    required init(window: UIWindow) {
        self.window = window
    }

    @discardableResult
    func transition(to scene: TargetScene) -> Observable<Void> {
        let subject = PublishSubject<Void>()
        
        switch scene.transition {
        case let .root(viewController):
            self.window.rootViewController = NavigationController(rootViewController: viewController);
            subject.onCompleted()
        case let .present(viewController):
            self.window.rootViewController?.present(viewController, animated: true, completion: {
                subject.onCompleted()
            })
        case let .alert(viewController):
            self.window.rootViewController?.present(viewController, animated: true, completion: {
                subject.onCompleted()
            })
        case let .push(viewController):
            (self.window.rootViewController as! UINavigationController).pushViewController(viewController, animated: true)
            subject.onCompleted()
        case let .tabBar(tabBarController):
            self.window.rootViewController = tabBarController
            subject.onCompleted()
        }
        
        return subject.asObservable().take(1)
    }
    
    @discardableResult
    func pop(animated: Bool) -> Observable<Void> {
        let subject = PublishSubject<Void>()
        
        return subject.asObservable().take(1)
    }
}
