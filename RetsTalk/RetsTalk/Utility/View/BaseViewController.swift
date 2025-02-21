//
//  BaseViewController.swift
//  RetsTalk
//
//  Created on 11/27/24.
//

import Combine
import UIKit

class BaseViewController: UIViewController {
    var subscriptionSet: Set<AnyCancellable>
    
    // MARK: Initialization
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        subscriptionSet = []
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        subscriptionSet = []
        
        super.init(coder: coder)
    }
    
    // MARK: ViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupDataSource()
        setupDelegation()
        setupNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupSubscription()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        subscriptionSet.removeAll()
    }
    
    // MARK: RetsTalk lifecycle
    
    func setupDataSource() {}
    
    func setupDelegation() {}
    
    func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = .blazingOrange
    }
    
    func setupSubscription() {}
}
