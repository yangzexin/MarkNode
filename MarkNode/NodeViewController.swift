//
//  NodeViewController.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import UIKit

class NodeViewController: BaseViewController, UIScrollViewDelegate, TSMindViewDelegate, BindableType {
    var scrollView: TSScrollView!
    var centerLayout: UIView!
    var mindView: TSMindView!
    
    var viewModel: NodeViewModel!
    
    override func loadView() {
        super.loadView()
        configureScrollView()
        configureCenterLayout()
        configureMindView()
    }
    
    func bindViewModel() {
        let output = viewModel.output
        output.node
            .subscribe { [weak self] e in
                switch e {
                case .next(let node):
                    self?.mindView.setNode(node, animated: true)
                case .error(let err):
                    print(err)
                case .completed:
                    break
                }
            }
            .disposed(by: disposeBag)
        output.title
            .bind(to: self.navigationItem.rx.title)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        self._viewNode(file: "demo.md", urlString: nil)
    }
    
    func _viewNode(file: String?, urlString: String?) {
        self.sf_setWaiting(true)
        var reader: TSMarkDownReader!
        if let file = file {
            reader = TSMarkDownReader(file: file)
        } else {
            reader = TSMarkDownReader(urlString: urlString!)
        }
        self.sf_send(SFWrappableServant(servant: reader)?.mainThreadFeedback(), success: { [weak self] node in
            self?.sf_setWaiting(false)
            self?.mindView.setNode(node as! TSNode, animated: true)
        }, error: { [weak self] err in
            self?.sf_setWaiting(false)
        })
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return centerLayout
    }
}
