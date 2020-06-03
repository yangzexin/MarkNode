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
    @IBOutlet var displaySelectorView: DisplaySelectorView!
    
    @IBOutlet var scrollView: TSScrollView!
    @IBOutlet var centerLayout: UIView!
    @IBOutlet var mindView: TSMindView!
    
    var viewModel: NodeViewModel!
    
    override func loadView() {
        super.loadView()
        configureScrollView()
        configureCenterLayout()
        configureMindView()
        configureOperationButtonView()
        configureBarButtons()
    }
    
    func bindViewModel() {
        let output = viewModel.output
        let input = viewModel.input
        
        output.node
            .bind { [weak self] node in
                self?.mindView.setNode(node, animated: true)
            }
            .disposed(by: disposeBag)
        output.title
            .bind(to: self.navigationItem.rx.title)
            .disposed(by: disposeBag)
        output.loading
            .bind { [weak self] loading in self?.sf_setLoading(loading)}
            .disposed(by: disposeBag)
        output.errorMessage
            .bind { msg in
                SFToast.toast(withText: msg, hideAfterSeconds: 2.0, identifier: "ID_errorMSG")
            }
            .disposed(by: disposeBag)
        output.loadLinkedNode
            .flatMap { Observable<Node>.just(Node(title: $0.lastPathComponent(), storeType: .remote, path: $0)) }
            .flatMap { node -> Observable<Node> in
                return Observable.create({ observer -> Disposable in
                    UIAlertView.sf_alert(withTitle: "Linked Node", message: "\(node.path)", completion: { (buttonIndex, buttonTitle) in
                        if buttonIndex == 0 {
                            observer.onCompleted()
                            input.selectLastSelectedNodeAction.onNext(())
                            return
                        }
                        observer.onNext(node)
                    }, cancelButtonTitle: "Cancel", otherButtonTitleList: ["Open"])
                    return Disposables.create {}
                })
            }
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
        let getNodeFrame: (TSNode) -> Observable<CGRect> = { [weak self] node -> Observable<CGRect> in
            guard let self = self, let selection = self.mindView.selection(for: node) else { return .empty() }
            var frame = selection.frame
            frame.origin.x += self.mindView.frame.origin.x
            frame.origin.y += self.mindView.frame.origin.y
            frame.origin.x *= self.scrollView.zoomScale
            frame.origin.y *= self.scrollView.zoomScale
            return .just(frame)
        }
        let scrollToShowNode: (CGRect) -> Void = { [weak self] frame in
            guard let self = self else { return }
            var contentOffset = self.scrollView.contentOffset
            var contentOffsetChanged = false
            let delta = CGPoint(x: 20, y: 20)
            let scrollViewSize = self.scrollView.frame.size
            
            if !(frame.origin.x >= contentOffset.x && (frame.origin.x + (frame.size.width * self.scrollView.zoomScale) <= contentOffset.x + scrollViewSize.width)) {
                contentOffsetChanged = true
                if frame.origin.x < contentOffset.x {
                    contentOffset.x = frame.origin.x - delta.x
                } else {
                    contentOffset.x = frame.origin.x + (frame.size.width * self.scrollView.zoomScale) + delta.x - scrollViewSize.width
                }
            }
            if !(frame.origin.y >= contentOffset.y && (frame.origin.y + (frame.size.height * self.scrollView.zoomScale) <= contentOffset.y + scrollViewSize.height)) {
                contentOffsetChanged = true
                if frame.origin.y < contentOffset.y {
                    contentOffset.y = frame.origin.y + delta.y
                } else {
                    contentOffset.y = frame.origin.y + (frame.size.height * self.scrollView.zoomScale) + delta.y - scrollViewSize.height
                }
            }
            if contentOffsetChanged {
                self.scrollView.setContentOffset(contentOffset, animated: true)
            }
        }
        output.selectedNode
            .flatMap { [weak self] node -> Observable<TSNode> in
                if let node = node {
                    return .just(node)
                }
                guard let self = self else { return .empty() }
                if self.mindView.selectedNode != nil {
                    self.mindView.selectedNode = nil
                }
                return .empty()
            }
            .flatMap { [weak self] node -> Observable<TSNode> in
                if node != self?.mindView.selectedNode {
                    self?.mindView.selectedNode = node
                }
                return .just(node)
            }
            .flatMap(getNodeFrame)
            .bind(onNext: scrollToShowNode)
            .disposed(by: disposeBag)
        
        mindView.rx.itemSelected
            .flatMap { mindNodeView -> Observable<TSNode?> in
                guard let selectedNodeView = mindNodeView else { return .just(nil) }
                return .just(selectedNodeView.node!)
            }
            //.distinctUntilChanged()
            .bind(to: input.selectNodeAction)
            .disposed(by: disposeBag)
        
        output.scrollToShowNode.flatMap(getNodeFrame).bind(onNext: scrollToShowNode).disposed(by: disposeBag)
        output.scrollToShowNodeAtCenter
            .flatMap(getNodeFrame)
            .bind { [weak self] frame in
                guard let self = self else { return }
                let centerX = frame.origin.x + frame.size.width / 2
                let centerY = frame.origin.y + frame.size.height / 2
                let contentOffset = CGPoint(x: centerX - self.scrollView.frame.size.width / 2, y: centerY - self.scrollView.frame.size.height / 2)
                
                self.scrollView.setContentOffset(contentOffset, animated: false)
            }
            .disposed(by: disposeBag)
        
        output.nodeSelectState
            .flatMap { [weak self] selectState -> Observable<CGRect> in
                guard let self = self else { return .empty() }
                var frame = self.operationButtonView.frame
                if selectState {
                    frame.origin.y = self.view.frame.size.height - frame.size.height - 10
                } else {
                    frame.origin.y = self.view.frame.size.height
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
                guard let self = self else { return }
                self.mindView.setEditing(true, node: node)
            })
            .disposed(by: disposeBag)
        deleteButton.rx.tap
            .flatMap(selectedNodeSelector)
            .flatMap { node -> Observable<TSNode> in
                return Observable<TSNode>.create({ (observer) -> Disposable in
                    UIAlertView.sf_alert(withTitle: "\(node.title)", message: nil, completion: { (buttonIndex, buttonTitle) in
                        if buttonIndex == 0 {
                            observer.onCompleted()
                            return
                        }
                        observer.onNext(node)
                    }, cancelButtonTitle: "Cancel", otherButtonTitleList: ["Delete"])
                    return Disposables.create {}
                })
            }
            .subscribe(onNext: { [weak self] node -> Void in
                guard let self = self else { return }
                input.deleteNodeAction.onNext(node)
                self.mindView.removeNode(node, animated: true)
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
                guard let self = self else { return .empty() }
                let contentSize = self.scrollView.contentSize
                let frameSize = self.scrollView.frame.size
                return .just(CGPoint(x: (contentSize.width - frameSize.width) / 2, y: (contentSize.height - frameSize.height) / 2))
            }
            .bind(to: self.scrollView.rx.contentOffset)
            .disposed(by: disposeBag)
        mindView.rx.didUpdateSize
            .bind { [weak self] handle in
                guard let self = self else { return }
                let size = handle.size
                var frame = self.centerLayout.frame;
                let containerSize = CGSize(width: size.width + 1000, height: size.height + 1000);
                frame.size = containerSize;
                self.centerLayout.frame = frame;
                
                frame = self.mindView.frame;
                frame.size = CGSize(width: containerSize.width - 10, height: containerSize.height - 10);
                self.mindView.frame = frame;
                
                self.scrollView.contentSize = containerSize;
                handle.didUpdate = true
            }
            .disposed(by: disposeBag)
        
        output.uiRegistries.bind { uiRegistries in
            self.displaySelectorView.uiRegistries = uiRegistries
        }.disposed(by: disposeBag)
        
        self.navigationItem.rightBarButtonItem!.rx.tap
            .flatMap { [weak self] _ -> Observable<Bool> in
                guard let self = self else { return .empty() }
                return .just(self.displaySelectorView.isHidden)
            }
            .bind { [weak self] visible in
                guard let self = self else { return }
                if visible {
                    self.displaySelectorView.isHidden = false
                }
                self.displaySelectorView.show(visible: visible, animated: true) {
                    if !visible {
                        self.displaySelectorView.isHidden = true
                    }
                }
            }
            .disposed(by: disposeBag)
        output.style.bind(to: mindView.rx.style).disposed(by: disposeBag)
        output.layouter.bind(to: mindView.rx.layouter).disposed(by: disposeBag)
        self.displaySelectorView.rx.didClose.bind { [weak self] in
            guard let self = self else { return }
            self.displaySelectorView.show(visible: false, animated: true, completion: {
                self.displaySelectorView.isHidden = true
            })
        }.disposed(by: disposeBag)
        self.displaySelectorView.rx.didSelectStyle
            .flatMap { styleRegistry -> Observable<TSMindViewStyle> in
                .just(styleRegistry.create())
            }
            .bind(to: input.selectStyleAction)
            .disposed(by: disposeBag)
        self.displaySelectorView.rx.didSelectLayout
            .flatMap { layouterRegistry -> Observable<TSLayouterProtocol> in
                .just(layouterRegistry.create())
            }
            .bind(to: input.selectLayouterAction)
            .disposed(by: disposeBag)
    }
    
    func configureScrollView() {
        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 1.0
        scrollView.scrollsToTop = false
    }
    
    func configureCenterLayout() {
        centerLayout.frame = CGRect(x: 0, y: 0, width: 5020, height: 5020)
        scrollView.centerView = centerLayout
        scrollView.contentSize = centerLayout.bounds.size
    }
    
    func configureMindView() {
        mindView.frame = CGRect(x: 0, y: 0, width: 5000, height: 5000)
        mindView.delegate = self
    }
    
    func configureOperationButtonView() {
        var frame = self.operationButtonView.frame
        frame.origin.y = self.view.frame.size.height
        self.operationButtonView.frame = frame
    }
    
    func configureBarButtons() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: "⍚".sf_image(with: UIFont.systemFont(ofSize: 27), textColor: UIColor.black), style: .plain, target: nil, action: nil)
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
