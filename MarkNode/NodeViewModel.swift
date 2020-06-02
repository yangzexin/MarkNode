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
    var selectNodeAction: AnyObserver<TSNode?> { get }
    var addSubNodeAction: AnyObserver<TSNode> { get }
    var addAsNextSibAction: AnyObserver<TSNode> { get }
    var deleteNodeAction: AnyObserver<TSNode> { get }
    var loadNodeAction: AnyObserver<Node> { get }
}

protocol NodeViewModelOutput {
    var node: PublishSubject<TSNode> { get }
    var title: BehaviorSubject<String> { get }
    var selectedNode: BehaviorSubject<TSNode?> { get }
    var nodeSelectState: BehaviorSubject<Bool> { get }
    var errorMessage: PublishSubject<String> { get }
    var loading: BehaviorSubject<Bool> { get }
    var loadLinkedNode: PublishSubject<String> { get }
}

protocol NodeViewModelType {
    var input: NodeViewModelInput { get }
    var output: NodeViewModelOutput { get }
}

class NodeViewModel: NodeViewModelType, NodeViewModelInput, NodeViewModelOutput {
    var input: NodeViewModelInput { return self }
    var output: NodeViewModelOutput { return self }
    
    var node = PublishSubject<TSNode>()
    var rootNode: TSNode!
    var title: BehaviorSubject<String>
    var errorMessage = PublishSubject<String>()
    var loading = BehaviorSubject<Bool>(value: false)
    var loadLinkedNode = PublishSubject<String>()
    
    var selectedNode = BehaviorSubject<TSNode?>(value: nil)
    var nodeSelectState = BehaviorSubject<Bool>(value: false)
    
    var disposeBag = DisposeBag()
    
    var service: NodeServiceType!
    
    lazy var selectNodeAction: AnyObserver<TSNode?> = {
        AnyObserver<TSNode?> { [weak self] e in
            switch e {
            case .next(var node):
                guard let this = self else { return }
                if let node = node {
                    if let link = node.attributes?.findMatching(left: "link-node=", right: "\n") {
                        this.loadLinkedNode.onNext(link)
                        this.selectedNode.onNext(nil)
                        this.nodeSelectState.onNext(false)
                        return
                    }
                    this.selectedNode.onNext(node)
                    this.nodeSelectState.onNext(true)
                } else {
                    this.selectedNode.onNext(nil)
                    this.nodeSelectState.onNext(false)
                }
            default:
                break
            }
        }
    }()
    
    lazy var addSubNodeAction: AnyObserver<TSNode> = {
        AnyObserver<TSNode> { [weak self] e in
            switch e {
                case .next(let targetNode):
                    guard let this = self else { return }
                    let newNode = targetNode.addAsSub(withTitle: "New")
                    this.node.onNext(this.rootNode)
                    this.selectedNode.onNext(newNode)
                default:
                    break
            }
        }
    }()
    
    lazy var addAsNextSibAction: AnyObserver<TSNode> = {
        AnyObserver<TSNode> { [weak self] e in
            switch e {
            case .next(let targetNode):
                guard let this = self else { return }
                let newNode = targetNode.addAsNextSibling(withTitle: "New")
                this.node.onNext(this.rootNode)
                this.selectedNode.onNext(newNode)
            default:
                break
            }
        }
    }()
    
    lazy var deleteNodeAction: AnyObserver<TSNode> = {
        AnyObserver<TSNode> { [weak self] e in
            switch e {
            case .next(let targetNode):
                guard let this = self else { return }
                this.selectedNode.onNext(targetNode.parent)
            default:
                break
            }
        }
    }()
    
    lazy var loadNodeAction: AnyObserver<Node> = {
        AnyObserver<Node> { [weak self] e in
            switch e {
            case .next(let node):
                guard let this = self else { return }
                this.loading.onNext(true)
                this.service.detail(node)
                    .flatMap { result -> Observable<TSNode> in
                        switch result {
                        case let .success(node):
                            return .just(node)
                        case .failure(_):
                            return .empty()
                        }
                    }
                    .catchError { [weak self] _ in
                        self?.loading.onNext(false)
                        self?.errorMessage.onNext("Error on Loading: \(node.title)")
                        return .empty()
                    }
                    .bind { [weak self] node in
                        self?.loading.onNext(false)
                        self?.node.onNext(node)
                        self?.title.onNext(node.title)
                        self?.rootNode = node
                    }
                    .disposed(by: this.disposeBag)
            default:
                break
            }
        }
    }()
    
    init(_ node_: Node, service: NodeServiceType = NodeService()) {
        self.service = service
        title = BehaviorSubject<String>(value: node_.title)
        
        loadNodeAction.onNext(node_)
    }
    
}
