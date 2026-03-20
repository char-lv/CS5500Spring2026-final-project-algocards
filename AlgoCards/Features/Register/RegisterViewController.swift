//
//  RegisterViewController.swift
//  AlgoCards
//
//  Created by Jia-Wen Wan on 19/3/26.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class RegisterViewController: UIViewController {

    let registerView = RegisterView()
    
    override func loadView() {
        view = registerView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.prefersLargeTitles = true
        registerView.signUpButton.addTarget(self, action: #selector(onRegisterTapped), for: .touchUpInside)
        setupActions()
    }
    
    private func setupActions() {
        registerView.onSignInTapped = { [weak self] in
            self?.navigateToSignIn()
        }
    }
    
    private func navigateToSignIn() {
        // Navigate explicitly to LoginViewController
        if let navigationController = navigationController {
            for controller in navigationController.viewControllers {
                if controller is LoginViewControllerMain {
                    navigationController.popToViewController(controller, animated: true)
                    return
                }
            }
        }
        
        // If LoginViewController is not in the stack, push it
        let loginViewController = LoginViewControllerMain()
        navigationController?.pushViewController(loginViewController, animated: true)
    }
    
    @objc private func onRegisterTapped() {

        guard let password = registerView.passwordTextField.text,
              let confirmPassword = registerView.confirmPasswordTextField.text else {
            return
        }
        
        // Check if passwords match
        if password != confirmPassword {
            // Show error alert
            let alert = UIAlertController(
                title: "Error",
                message: "Passwords do not match. Please try again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        // Proceed with registration
        registerNewAccount { isSuccess in
            if isSuccess {
                let alert = UIAlertController(
                    title: "Success",
                    message: "Registered successfully! Please log in.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                UserDefaults.standard.set(true, forKey: "isFirstLogin")
                self.present(alert, animated: true, completion: nil)
            }
        }
    }


}