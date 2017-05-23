//
//  ViewController.swift
//  TestAlamofire
//
//  Created by 田腾飞 on 2016/12/12.
//  Copyright © 2016年 田腾飞. All rights reserved.
//

import UIKit
import RxSwift

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let viewModel = ViewModel()
    let disposeBag = DisposeBag()
    var models: [Model]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.dataSource = self
        
        viewModel.getCategories()
            .subscribe({ [unowned self] event in
                
                print (Thread.current)
                switch event {
                case .next(let models):
                    self.models = models.data?.data
                    self.tableView.reloadData()
                case .error(let error):
                    print(error)
                case .completed:
                    return
                }
            })
            .addDisposableTo(disposeBag)
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let models = models else {
            return 0
        }
        return models.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = models?[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        if let model = model {
            cell.textLabel?.text = model.name
            cell.detailTextLabel?.text = model.category
        }
        return cell
    }
}

