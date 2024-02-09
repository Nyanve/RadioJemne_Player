//
//  ViewController+Ext.swift
//  RadioJemne
//
//  Created by Samuel Brezoňák on 02/02/2024.
//

import UIKit


extension ViewController {
    
    func basicError(message: String) {
        let error = UIAlertController(title: "Error occurred 😏", message: message, preferredStyle: .alert)
        error.addAction(UIAlertAction(title: "Ok", style: .cancel))
        
        self.present(error, animated: true)
    }
}
