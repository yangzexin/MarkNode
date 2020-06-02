//
//  NodeViewController.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import UIKit
import RxSwift

class NodeViewController: BaseViewController, UIScrollViewDelegate, TSMindViewDelegate, BindableType {
    @IBOutlet var operationButtonView: UIView!
    @IBOutlet var editButton: UIButton!
    @IBOutlet var deleteButton: UIButton!
    @IBOutlet var addButton: UIButton!
    @IBOutlet var addToButton: UIButton!
    
    var scrollView: TSScrollView!
    var centerLayout: UIView!
    var mindView: TSMindView!
    
    var viewModel: NodeViewModel!
    
    override func loadView() {
        super.loadView()
        configureScrollView()
        configureCenterLayout()
        configureMindView()
        configureOperationButtonView()
    }
    
    func bindViewModel() {
        let output = viewModel.output
        let input = viewModel.input
        
        output.loading.bind { [weak self] loading in self?.sf_setWaiting(loading)}.disposed(by: disposeBag)
        output.node
            .bind { [weak self] node in
                self?.mindView.setNode(node, animated: true)
            }
            .disposed(by: disposeBag)
        output.title
            .bind(to: self.navigationItem.rx.title)
            .disposed(by: disposeBag)
        output.errorMessage
            .bind { msg in
                SFToast.toast(withText: msg, hideAfterSeconds: 2.0, identifier: "ID_errorMSG")
            }
            .disposed(by: disposeBag)
        output.loadLinkedNode
            .flatMap { Observable<Node>.just(Node(title: $0.lastPathComponent(), storeType: .remote, path: $0)) }
            .bind(to: input.loadNodeAction)
            .disposed(by: disposeBag)
        output.selectedNode
            .flatMap { node -> Observable<Bool> in
                if let _ = node {
                    return .empty()
                }
                return .just(true)
            }
            .bind { [weak self] _ in
                if let _ = self?.isFirstResponder {
                    self?.resignFirstResponder()
                    self?.view.endEditing(true)
                }
            }
            .disposed(by: disposeBag)
        output.selectedNode
            .flatMap { [weak self] node -> Observable<TSNode> in
                if let node = node {
                    return .just(node)
                }
                if let this = self {
                    if this.mindView.selectedNode != nil {
                        this.mindView.selectedNode = nil
                    }
                }
                return .empty()
            }
            .flatMap { [weak self] node -> Observable<TSNode> in
                if node != self?.mindView.selectedNode {
                    self?.mindView.selectedNode = node
                }
                return .just(node)
            }
            .flatMap { [weak self] node -> Observable<CGRect> in
                guard let this = self else { return .empty() }
                guard let selection = this.mindView.selection(for: node) else { return .empty() }
                var frame = selection.frame
                frame.origin.x += this.mindView.frame.origin.x
                frame.origin.y += this.mindView.frame.origin.y
                frame.origin.x *= this.scrollView.zoomScale
                frame.origin.y *= this.scrollView.zoomScale
                return .just(frame)
            }
            .bind { [weak self] frame in
                guard let this = self else { return }
                var contentOffset = this.scrollView.contentOffset
                var contentOffsetChanged = false
                let delta = CGPoint(x: 20, y: 20)
                let scrollViewSize = this.scrollView.frame.size
                
                if !(frame.origin.x >= contentOffset.x && (frame.origin.x + frame.size.width <= contentOffset.x + scrollViewSize.width)) {
                    contentOffsetChanged = true
                    if frame.origin.x < contentOffset.x {
                        contentOffset.x = frame.origin.x - delta.x
                    } else {
                        contentOffset.x = frame.origin.x + frame.size.width + delta.x - scrollViewSize.width
                    }
                }
                if !(frame.origin.y >= contentOffset.y && (frame.origin.y + frame.size.height <= contentOffset.y + scrollViewSize.height)) {
                    contentOffsetChanged = true
                    if frame.origin.y < contentOffset.y {
                        contentOffset.y = frame.origin.y + delta.y
                    } else {
                        contentOffset.y = frame.origin.y + frame.size.height + delta.y - scrollViewSize.height
                    }
                }
                if contentOffsetChanged {
                    this.scrollView.setContentOffset(contentOffset, animated: true)
                }
            }
            .disposed(by: disposeBag)
        
        mindView.rx.itemSelected
            .flatMap { mindNodeView -> Observable<TSNode?> in
                    guard let selectedNodeView = mindNodeView else { return .just(nil) }
                    return .just(selectedNodeView.node!)
            }
            //.distinctUntilChanged()
            .bind(to: input.selectNodeAction)
            .disposed(by: disposeBag)
        
        output.nodeSelectState
            .flatMap { [weak self] selectState -> Observable<CGRect> in
                guard let this = self else { return .empty() }
                var frame = this.operationButtonView.frame
                if selectState {
                    frame.origin.y = this.view.frame.size.height - frame.size.height - 10
                } else {
                    frame.origin.y = this.view.frame.size.height
                }
                return .just(frame)
            }
            .bind { frame in
                UIView.animate(withDuration: 0.25, animations: {
                    self.operationButtonView.frame = frame
                })
            }
            .disposed(by: disposeBag)

        let selectedNodeSelector: () -> Observable<TSNode> = { [weak self] in
            if let node = self?.mindView.selectedNode {
                return .just(node)
            }
            return .empty()
        }
        editButton.rx.tap
            .flatMap(selectedNodeSelector)
            .subscribe(onNext: { [weak self] node -> Void in
                guard let this = self else { return }
                this.mindView.setEditing(true, node: node)
            })
            .disposed(by: disposeBag)
        deleteButton.rx.tap
            .flatMap(selectedNodeSelector)
            .subscribe(onNext: { [weak self] node -> Void in
                guard let this = self else { return }
                input.deleteNodeAction.onNext(node)
                this.mindView.removeNode(node, animated: true)
            })
            .disposed(by: disposeBag)
        addToButton.rx.tap
            .flatMap(selectedNodeSelector)
            .bind(to: input.addSubNodeAction)
            .disposed(by: disposeBag)
        addButton.rx.tap
            .flatMap(selectedNodeSelector)
            .bind(to: input.addAsNextSibAction)
            .disposed(by: disposeBag)
        
        mindView.rx.finishLayout
            .take(1)
            .flatMap { [weak self] Void -> Observable<CGPoint> in
                guard let this = self else { return .empty() }
                let contentSize = this.scrollView.contentSize
                let frameSize = this.scrollView.frame.size
                return .just(CGPoint(x: (contentSize.width - frameSize.width) / 2, y: (contentSize.height - frameSize.height) / 2))
            }
            .bind(to: self.scrollView.rx.contentOffset)
            .disposed(by: disposeBag)
    }
    
    func configureScrollView() {
        scrollView = TSScrollView(frame: self.view.bounds)
        scrollView.autoresizingMask = UIView.AutoresizingMask(rawValue: UIView.AutoresizingMask.flexibleWidth.rawValue | UIView.AutoresizingMask.flexibleHeight.rawValue)
        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 1.0
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.backgroundColor = UIColor.white
        scrollView.delegate = self
        self.view.addSubview(scrollView)
    }
    
    func configureCenterLayout() {
        centerLayout = UIView(frame: CGRect(x: 0, y: 0, width: 4010, height: 4010))
        scrollView.addSubview(centerLayout)
        scrollView.centerView = centerLayout
        scrollView.contentSize = centerLayout.bounds.size
    }
    
    func configureMindView() {
        mindView = TSMindView(frame: CGRect(x: 0, y: 0, width: 4000, height: 4000))
        mindView.delegate = self
        mindView.backgroundColor = UIColor.clear
        centerLayout.addSubview(mindView)
    }
    
    func configureOperationButtonView() {
        var frame = self.operationButtonView.frame
        frame.origin.y = self.view.frame.size.height
        self.operationButtonView.frame = frame
        self.view.bringSubviewToFront(self.operationButtonView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return centerLayout
    }
}
