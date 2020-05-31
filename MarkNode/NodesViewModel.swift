//
//  NodesViewModel.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

protocol NodesViewModelInput {
    var nodeDetailAction: AnyObserver<Node> { get }
}

protocol NodesViewModelOutput {
    var isLoading: Observable<Bool> { get }
    var title: BehaviorSubject<String> { get }
    var nodes: Observable<[Node]> { get }
    var nodeViewModels: Observable<[NodeCellViewModel]> { get }
}

protocol NodesViewModelType {
    var input: NodesViewModelInput { get }
    var output: NodesViewModelOutput { get }
}

class NodesViewModel: NodesViewModelType, NodesViewModelInput, NodesViewModelOutput {
    var input: NodesViewModelInput { return self }
    var output: NodesViewModelOutput { return self }
    
    let isLoading: Observable<Bool>
    let title: BehaviorSubject<String>
    
    let nodes: Observable<[Node]>
    
    lazy var nodeViewModels: Observable<[NodeCellViewModel]> = {
        nodes.map { list in
            list.map { NodeCellViewModel(node: $0) }
        }
    }()
    
    lazy var nodeDetailAction: AnyObserver<Node> = AnyObserver<Node> { event in
        switch event {
        case .next(let node):
            self.sceneCoordinator.transition(to: Scene.detail(NodeViewModel(node)))
        default:
            break
        }
    }
    
    // MARK: private
    private let sceneCoordinator: SceneCoordinatorType
    
    init(service: NodeServiceType = NodeService(), sceneCoordinator: SceneCoordinatorType = SceneCoordinator.shared) {
        self.sceneCoordinator = sceneCoordinator
        
        let loadingProperty = BehaviorSubject(value: true)
        isLoading = loadingProperty.asObservable()
        title = BehaviorSubject(value: "MarkNode")
        
        nodes = service.list().flatMap { result -> Observable<[Node]> in
            loadingProperty.onNext(false)
            switch result {
            case let .success(nodes):
                return .just(nodes)
            case .failure(_):
                return .empty()
            }
        }
    }
}
