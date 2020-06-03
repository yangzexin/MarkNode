//
//  StyleSelectorView.swift
//  MarkNode
//
//  Created by yangzexin on 2020/6/2.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import UIKit

class StyleSelectorView: SFIBCompatibleView, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet private var tableView: UITableView!
    
    var styleRegistries: [TSMindViewStyleRegistry]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var didSelectStyle: ((TSMindViewStyleRegistry) -> Void)?;
    
    override func initCompat() {
        super.initCompat()
        self.sf_load(fromXibName: String(describing: StyleSelectorView.self))
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "StyleCell")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let styleRegistry = styleRegistries?[indexPath.row], let selectHandler = didSelectStyle {
            selectHandler(styleRegistry)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let styles = self.styleRegistries else { return 0 }
        return styles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StyleCell")
        let style = self.styleRegistries![indexPath.row]
        cell!.textLabel?.text = style.name
        return cell!
    }
}
