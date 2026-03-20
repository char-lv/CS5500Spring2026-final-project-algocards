// ARCHIVED - This landing flow is not active in the current app.
// The live auth entry point is: SceneDelegate.showAuth() → AuthViewController.
// Nothing in the live navigation stack routes here.
//
//  LogInViewController.swift
//  AlgoCards
//
//  Created by Jia-Wen Wan on 19/3/26.
//

import UIKit

class LandingViewController: UIViewController {
    

    //MARK: add the view to this controller while the view is loading...
    
    private let landingView = LandingView()

    override func loadView() {
        view = landingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
    }
    
    private func setupActions() {
        landingView.signInButton.addTarget(self, action: #selector(onSignInTapped), for: .touchUpInside)
        landingView.signUpButton.addTarget(self, action: #selector(onSignUpTapped), for: .touchUpInside)
    }
    
    @objc private func onSignInTapped() {
        let loginViewController = LoginViewControllerMain()
        navigationController?.pushViewController(loginViewController, animated: true)
    }
    
    @objc private func onSignUpTapped() {
        let registerViewController = RegisterViewController()
        navigationController?.pushViewController(registerViewController, animated: true)
    }
}