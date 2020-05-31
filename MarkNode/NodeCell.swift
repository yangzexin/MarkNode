//
//  NodeCell.swift
//  MarkNode
//
//  Created by yangzexin on 2020/5/30.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class NodeCell: UITableViewCell, BindableType {
    
    @IBOutlet
    var nodeTitleLabel: UILabel!
    
    @IBOutlet
    var nodeImageView: UIImageView!
    
    var viewModel: NodeCellViewModel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(title: String, image: UIImage?) {
        nodeTitleLabel.text = title
        nodeImageView.image = image
    }
    
    func bindViewModel() {
        let output = viewModel.output
        
        output.title.bind(to: nodeTitleLabel.rx.text).disposed(by: disposeBag)
        output.image.bind(to: nodeImageView.rx.image).disposed(by: disposeBag)
    }
}
