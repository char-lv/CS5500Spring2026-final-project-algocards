//
//  LoginViewController.swift
//  AlgoCards
//
//  Created by Jia-Wen Wan on 19/3/26.
//

import UIKit
import FirebaseAuth
import Firebase
import FBSDKLoginKit
import GoogleSignIn
import FirebaseCore

class LoginViewControllerMain: UIViewController {
    
    
    var window: UIWindow?
    private let loginView = LoginView()

    override func loadView() {
        view = loginView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupActions()
        checkLoginState()
    }

    private func setupActions() {
        loginView.signInButton.addTarget(self, action: #selector(onSignInTapped), for: .touchUpInside)
        loginView.facebookButton.addTarget(self, action: #selector(onFacebookSignInTapped), for: .touchUpInside)
        loginView.googleButton.addTarget(self, action: #selector(onGoogleSignInTapped), for: .touchUpInside)
        
        // Handle navigation to Sign Up
        loginView.onSignUpTapped = { [weak self] in
            self?.navigateToSignUp()
        }
    }
    
    private func navigateToSignUp() {
        let registerViewController = RegisterViewController()
        navigationController?.pushViewController(registerViewController, animated: true)
    }

    @objc private func onSignInTapped() {
        let email = loginView.emailTextField.text ?? ""
        let password = loginView.passwordTextField.text ?? ""
        
        guard !email.isEmpty else {
            showAlert(message: "Please enter your email.")
            return
        }
        
        guard !password.isEmpty else {
            showAlert(message: "Please enter your password.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.showAlert(message: "Incorrect Password or User Not Found. Please check your log in credentials and try again.")
            } else {
                let alert = UIAlertController(
                    title: "Success",
                    message: "Logged in successfully!",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    self?.switchMainApp()
                }))
                self?.present(alert, animated: true)
            }
        }
    }
    
    
    func switchMainApp() {
        // Tell the SceneDelegate to switch to the login screen
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
                    sceneDelegate.switchMainApp()
        } else {
            print("SceneDelegate not found")
        }
    }

    private func checkLoginState() {
        if let _ = Auth.auth().currentUser {
            setupRightBarButton(isLoggedin: true)
        } else {
            setupRightBarButton(isLoggedin: false)
        }
    }

    private func setupRightBarButton(isLoggedin: Bool) {
        if isLoggedin {
            let barText = UIBarButtonItem(
                title: "Logout",
                style: .plain,
                target: self,
                action: #selector(onLogoutTapped)
            )
            navigationItem.rightBarButtonItem = barText
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @objc private func onLogoutTapped() {
        do {
            try Auth.auth().signOut()
            showAlert(message: "Logged out successfully!")
            checkLoginState()
        } catch {
            showAlert(message: "Error signing out.")
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func onGoogleSignInTapped() {
        // Ensure the Firebase client ID is available
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        // Create a Google Sign-In configuration object
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Present the Google Sign-In flow
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            if let error = error {
                self.showAlert(message: "Google Sign-In failed: \(error.localizedDescription)")
                return
            }
            
            // Retrieve authentication tokens
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.showAlert(message: "Unable to retrieve Google authentication token.")
                return
            }
            
            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.showAlert(message: "Firebase sign-in failed: \(error.localizedDescription)")
                } else {
                    let alert = UIAlertController(
                        title: "Success",
                        message: "Logged in successfully!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        self.switchMainApp()
                    }))
                    self.present(alert, animated: true)
                }
            }
        }
    }

    
    @objc private func onFacebookSignInTapped() {
        let loginManager = LoginManager()
        loginManager.logIn(permissions: ["public_profile", "email"], from: self) { [weak self] result, error in
            if let error = error {
                self?.showAlert(message: "Facebook login failed: \(error.localizedDescription)")
                return
            }

            guard let result = result, !result.isCancelled else {
                self?.showAlert(message: "Facebook login cancelled.")
                return
            }

            // Get Facebook credential
            guard let tokenString = AccessToken.current?.tokenString else {
                self?.showAlert(message: "Failed to retrieve Facebook access token.")
                return
            }
            let credential = FacebookAuthProvider.credential(withAccessToken: tokenString)

            // Sign in with Firebase
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self?.showAlert(message: "Firebase sign in failed: \(error.localizedDescription)")
                } else {
                    let alert = UIAlertController(
                        title: "Success",
                        message: "Logged in successfully!",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        self?.switchMainApp()
                    }))
                    self?.present(alert, animated: true)
                }
            }
        }
    }

}