//
//  ViewController.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class NodesViewController: BaseViewController, BindableType {
    
    @IBOutlet var tableView: UITableView!
    
    var viewModel: NodesViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureTableView()
    }
    
    func bindViewModel() {
        let output = viewModel.output
        let input = viewModel.input
        output.isLoading
            .subscribe(onNext: { [weak self] loading in
                self?.sf_setWaiting(loading)
            })
            .disposed(by: disposeBag)
        output.title
            .bind(to: self.navigationItem.rx.title)
            .disposed(by: disposeBag)
        output.nodeViewModels
            .bind(to: tableView.rx.items(cellIdentifier: String(describing: NodeCell.self), cellType: NodeCell.self)) { row, cellViewModel, cell in
                var nodeCell = cell
                nodeCell.bind(to: cellViewModel)
            }
            .disposed(by: disposeBag)
        tableView.rx.itemSelected
            .flatMap { [weak self] indexPath -> Observable<IndexPath> in
                self?.tableView.deselectRow(at: indexPath, animated: true)
                return Observable.just(indexPath)
            }
            .flatMap { [weak self] indexPath -> Observable<Node> in
                let cell = self?.tableView.cellForRow(at: indexPath) as! NodeCell
                let cellViewModel = cell.viewModel!
                
                return cellViewModel.node
            }
            .bind(to: input.nodeDetailAction)
            .disposed(by: disposeBag)
    }
    
    func configureTableView() {
        tableView.register(UINib(nibName: String(describing: NodeCell.self), bundle: Bundle(for: NodeCell.self)), forCellReuseIdentifier: String(describing: NodeCell.self))
        tableView.rowHeight = 100.0
    }

}

