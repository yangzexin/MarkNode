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
    var selectLastSelectedNodeAction: AnyObserver<Void> { get }
    var selectStyleAction: AnyObserver<TSMindViewStyle> { get }
    var selectLayouterAction: AnyObserver<TSLayouterProtocol> { get }
    var refreshAction: AnyObserver<Void> { get }
}

protocol NodeViewModelOutput {
    var node: PublishSubject<TSNode> { get }
    var title: BehaviorSubject<String> { get }
    var selectedNode: BehaviorSubject<TSNode?> { get }
    var nodeSelectState: BehaviorSubject<Bool> { get }
    var errorMessage: PublishSubject<String> { get }
    var loading: BehaviorSubject<Bool> { get }
    var loadLinkedNode: PublishSubject<String> { get }
    var uiRegistries: Observable<TSUIRegistriesType> { get }
    var style: BehaviorSubject<TSMindViewStyle> { get }
    var layouter: BehaviorSubject<TSLayouterProtocol> { get }
    var scrollToShowNode: PublishSubject<TSNode> { get }
    var scrollToShowNodeAtCenter: PublishSubject<TSNode> { get }
}

protocol NodeViewModelType {
    var input: NodeViewModelInput { get }
    var output: NodeViewModelOutput { get }
}

class NodeViewModel: NodeViewModelType, NodeViewModelInput, NodeViewModelOutput {
    var input: NodeViewModelInput { return self }
    var output: NodeViewModelOutput { return self }
    
    var rootNode: TSNode!
    var lastSelectedNode: TSNode?
    
    var node = PublishSubject<TSNode>()
    var title: BehaviorSubject<String>
    var errorMessage = PublishSubject<String>()
    var loading = BehaviorSubject<Bool>(value: false)
    var loadLinkedNode = PublishSubject<String>()
    var uiRegistries: Observable<TSUIRegistriesType>
    var style = BehaviorSubject<TSMindViewStyle>(value: TSDefaultMindViewStyle.shared())
    var layouter = BehaviorSubject<TSLayouterProtocol>(value: TSStandardLayouter())
    var scrollToShowNode = PublishSubject<TSNode>()
    var scrollToShowNodeAtCenter = PublishSubject<TSNode>()
    
    var selectedNode = BehaviorSubject<TSNode?>(value: nil)
    var nodeSelectState = BehaviorSubject<Bool>(value: false)
    
    var disposeBag = DisposeBag()
    
    var service: NodeServiceType
    
    lazy var selectNodeAction: AnyObserver<TSNode?> = {
        AnyObserver<TSNode?> { [weak self] e in
            switch e {
            case .next(var node):
                guard let self = self else { return }
                if let node = node {
                    self.lastSelectedNode = node
                    if let link = node.attributes?.findMatching(left: "link-node=", right: "\n") {
                        self.loadLinkedNode.onNext(link)
                        self.selectedNode.onNext(nil)
                        self.nodeSelectState.onNext(false)
                        return
                    }
                    self.selectedNode.onNext(node)
                    self.nodeSelectState.onNext(true)
                } else {
                    self.selectedNode.onNext(nil)
                    self.nodeSelectState.onNext(false)
                }
            default:
                break
            }
        }
    }()
    
    lazy var selectLastSelectedNodeAction: AnyObserver<Void> = {
        AnyObserver<Void> { [weak self] e in
            switch e {
            case .next:
                guard let self = self else { return }
                self.selectedNode.onNext(self.lastSelectedNode)
                self.nodeSelectState.onNext(true)
            default:
                break;
            }
        }
    }()
    
    lazy var addSubNodeAction: AnyObserver<TSNode> = {
        AnyObserver<TSNode> { [weak self] e in
            switch e {
                case .next(let targetNode):
                    guard let self = self else { return }
                    let newNode = targetNode.addAsSub(withTitle: "New")
                    self.node.onNext(self.rootNode)
                    self.selectedNode.onNext(newNode)
                default:
                    break
            }
        }
    }()
    
    lazy var addAsNextSibAction: AnyObserver<TSNode> = {
        AnyObserver<TSNode> { [weak self] e in
            switch e {
            case .next(let targetNode):
                guard let self = self else { return }
                let newNode = targetNode.addAsNextSibling(withTitle: "New")
                self.node.onNext(self.rootNode)
                self.selectedNode.onNext(newNode)
            default:
                break
            }
        }
    }()
    
    lazy var deleteNodeAction: AnyObserver<TSNode> = {
        AnyObserver<TSNode> { [weak self] e in
            switch e {
            case .next(let targetNode):
                guard let self = self else { return }
                self.selectedNode.onNext(targetNode.parent)
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
                        guard let self = self else { return .empty() }
                        self.errorMessage.onNext("Error on Loading: \(node.title)")
                        self.loading.onNext(false)
                        return .empty()
                    }
                    .bind { [weak self] node in
                        guard let self = self else { return }
                        self.rootNode = node
                        self.node.onNext(node)
                        self.title.onNext(node.title)
                        self.loading.onNext(false)
                    }
                    .disposed(by: this.disposeBag)
            default:
                break
            }
        }
    }()
    
    lazy var selectStyleAction: AnyObserver<TSMindViewStyle> = {
        AnyObserver<TSMindViewStyle> { [weak self] e in
            guard let self = self else { return }
            switch e {
            case .next(let style):
                self.style.onNext(style)
                self.scrollToShowNode.onNext(self.rootNode)
                break
            default:
                break
            }
        }
    }()
    lazy var selectLayouterAction: AnyObserver<TSLayouterProtocol> = {
        AnyObserver<TSLayouterProtocol> { [weak self] e in
            guard let self = self else { return }
            switch e {
            case .next(let layout):
                self.layouter.onNext(layout)
                self.scrollToShowNode.onNext(self.rootNode)
                break
            default:
                break
            }
        }
    }()
    
    lazy var refreshAction: AnyObserver<Void> = {
        AnyObserver<Void> { [weak self] e in
            switch e {
            case .next:
                guard let self = self else { return }
                self.node.onNext(self.rootNode)
                self.scrollToShowNodeAtCenter.onNext(self.rootNode)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(500), execute: {
                })
                break
            default:
                break
            }
        }
    }()
    
    init(_ node_: Node, service: NodeServiceType = NodeService()) {
        self.service = service
        title = BehaviorSubject<String>(value: node_.title)
        uiRegistries = .just(TSUIRegistries.shared())
        
        loadNodeAction.onNext(node_)
    }
    
}
