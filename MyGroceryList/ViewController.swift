//
//  ViewController.swift
//  MyGroceryList
//
//  Created by Tyland on 1/18/22.
//

import CloudKit
import UIKit

class ViewController: UIViewController, UITableViewDataSource {
    

    let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UITableViewCell.self,
        forCellReuseIdentifier: "cell")
        
        return tableView
    }()
    
    private let database = CKContainer(identifier: "ICloud.iOSExample").publicCloudDatabase
    
    var items = [String]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Grocery List"
        view.addSubview(tableView)
        tableView.dataSource = self
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableView.refreshControl = control
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        
        fetchItems()
    }
    
    @objc func fetchItems() {
        let query = CKQuery(recordType: "groceryItem", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, error == nil else {
                return
            }
            DispatchQueue.main.async {
                self?.items = records.compactMap({ $0.value(forKey: "name") as? String })
                self?.tableView.reloadData()
            }
        }
    }
    
    @objc func pullToRefresh() {
        tableView.refreshControl?.beginRefreshing()
        let query = CKQuery(recordType: "groceryItem", predicate: NSPredicate(value: true))
        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let records = records, error == nil else {
                return
            }
            DispatchQueue.main.async {
                self?.items = records.compactMap({ $0.value(forKey: "name") as? String })
                self?.tableView.reloadData()
                self?.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    @objc func didTapAdd() {
        let alert = UIAlertController(title: "Add Item", message: nil, preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "Enter Name..."
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            if let field = alert.textFields?.first, let text = field.text, !text.isEmpty {
                self.saveItem(name: text)
            }
        }))
        present(alert, animated: true)
    }

    @objc func saveItem(name: String){
        let record = CKRecord(recordType: "GroceryItem")
        record.setValue(name, forKey: "name")
        database.save(record) { [weak self] record, error in
            if record != nil, error == nil {
                DispatchQueue.main.asyncAfter(deadline: .now()+2) {
                    self?.fetchItems()
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.textLabel?.text = "item"
        return cell
    }
}

