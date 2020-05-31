//
//  NodeViewModel.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import Foundation
import RxSwift

protocol NodeViewModelInput {
    
}

protocol NodeViewModelOutput {
    var node: Observable<TSNode> { get }
    var title: Observable<String> { get }
}

protocol NodeViewModelType {
    var input: NodeViewModelInput { get }
    var output: NodeViewModelOutput { get }
}

class NodeViewModel: NodeViewModelType, NodeViewModelInput, NodeViewModelOutput {
    var input: NodeViewModelInput { return self }
    var output: NodeViewModelOutput { return self }
    
    var node: Observable<TSNode>
    var title: Observable<String>
    
    init(_ node_: Node, service: NodeServiceType = NodeService()) {
        node = service.detail(node_)
            .flatMap { result -> Observable<TSNode> in
                switch result {
                case let .success(node):
                    return .just(node)
                case .failure(_):
                    return .empty()
                }
            }
        title = Observable.just(node_.title)
    }
    
}
