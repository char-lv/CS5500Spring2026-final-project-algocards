// ARCHIVED - This login flow is not active in the current app.
// The live auth entry point is: SceneDelegate.showAuth() → AuthViewController.
// FBSDKLoginKit and GoogleSignIn have been removed from imports because those
// SDKs are not in the Podfile. Social login is not yet implemented.

import UIKit
import FirebaseAuth
import Firebase
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
        if let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate {
            sceneDelegate.showMainApp()
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
        // Not implemented — GoogleSignIn SDK is not installed.
        showAlert(message: "Google Sign-In is not yet available.")
    }

    @objc private func onFacebookSignInTapped() {
        // Not implemented — FBSDKLoginKit SDK is not installed.
        showAlert(message: "Facebook Sign-In is not yet available.")
    }

}