//
//  LayoutSelectorView.swift
//  MarkNode
//
//  Created by yangzexin on 2020/6/2.
//  Copyright © 2020 yangzexin. All rights reserved.
//

import Foundation

class LayoutSelectorView: SFIBCompatibleView, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    var layoutRegistries: [TSLayouterRegistry]? {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var didSelectStyle: ((TSLayouterRegistry) -> Void)?
    
    override func initCompat() {
        super.initCompat()
        self.sf_load(fromXibName: String(describing: LayoutSelectorView.self))
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "LayoutCell")
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let layouterRegistry = layoutRegistries?[indexPath.row], let selectHandler = didSelectStyle {
            selectHandler(layouterRegistry)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let styles = self.layoutRegistries else { return 0 }
        return styles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LayoutCell")
        let layout = self.layoutRegistries![indexPath.row]
        cell!.textLabel?.text = layout.name
        return cell!
    }
}
