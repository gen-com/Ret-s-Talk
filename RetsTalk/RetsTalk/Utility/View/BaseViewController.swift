//
//  BaseViewController.swift
//  RetsTalk
//
//  Created on 11/27/24.
//

import UIKit

class BaseViewController: UIViewController {
    
    // MARK: Task collection
    
    var taskSet: Set<Task<Void, Never>>
    
    // MARK: Initialization
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        taskSet = []
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        taskSet = []
        
        super.init(coder: coder)
    }
    
    // MARK: ViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDataSource()
        setupDelegation()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupDataStream()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        for task in taskSet {
            task.cancel()
        }
    }
    
    // MARK: RetsTalk lifecycle
    
    func setupDataSource() {}
    
    func setupDelegation() {}
    
    func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .blazingOrange
    }
    
    func setupDataStream() {}
}
