//
//  Scene.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import UIKit

enum SceneTransitionType {
    case root(UIViewController)
    case push(UIViewController)
    case present(UIViewController)
    case alert(UIViewController)
    case tabBar(UITabBarController)
}

protocol TargetScene {
    var transition: SceneTransitionType { get }
}

enum Scene {
    case list
    case detail(NodeViewModel)
}

extension Scene: TargetScene {
    var transition: SceneTransitionType {
        switch self {
        case .list:
            var listVC = NodesViewController.initFromNib()
            listVC.bind(to: NodesViewModel())
            return .root(listVC)
        case let .detail(viewModel):
            var nodeVC = NodeViewController()
            nodeVC.bind(to: viewModel)
            return .push(nodeVC)
        }
    }
}
