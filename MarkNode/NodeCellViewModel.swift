//
//  NodeCellViewModel.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

protocol NodeCellViewModelInput {
}

protocol NodeCellViewModelOutput {
    var title: Observable<String> { get }
    var image: Observable<UIImage> { get }
    var node: Observable<Node> { get }
}

protocol NodeCellViewModelType {
    var input: NodeCellViewModelInput { get }
    var output: NodeCellViewModelOutput { get }
}

final class NodeCellViewModel: NodeCellViewModelType, NodeCellViewModelInput, NodeCellViewModelOutput {
    var input: NodeCellViewModelInput { return self }
    var output: NodeCellViewModelOutput { return self }
    
    let title: Observable<String>
    let image: Observable<UIImage>
    let node: Observable<Node>
    
    init(node _node: Node) {
        node = Observable.just(_node)
        title = node.map { $0.title }
        image = node.flatMap { node -> Observable<UIImage> in
            switch node.storeType {
            case .bundle:
                return .just(UIImage.sf_image(with: UIColor.red, size: CGSize(width: 10, height: 10)))
            case .remote:
                return .just(UIImage.sf_image(with: UIColor.blue, size: CGSize(width: 10, height: 10)))
            }
        }
    }
}
