//
//  UIViewController.swift
//  AlgoCards
//
//  Created by Minghui Xu on 2/26/26.
//

import Foundation
import UIKit

extension UIViewController {

    func showAlert(title: String = "Alert", message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completion?() })
        present(alert, animated: true)
    }

    func showSuccess(_ message: String, completion: (() -> Void)? = nil) {
        showAlert(title: "Success", message: message, completion: completion)
    }

    func showError(_ message: String) {
        showAlert(title: "Error", message: message)
    }
}
