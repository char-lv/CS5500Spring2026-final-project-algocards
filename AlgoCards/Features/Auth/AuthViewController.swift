//
//  AuthViewController.swift
//  AlgoCards
//

import UIKit

class AuthViewController: UIViewController {

    // MARK: - UI

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "AlgoCards"
        l.font = .boldSystemFont(ofSize: 34)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Master algorithms, one card at a time."
        l.font = .systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.borderStyle = .none
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 14
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let passwordField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.isSecureTextEntry = true
        tf.borderStyle = .none
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 14
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let usernameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username (sign up only)"
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.borderStyle = .none
        tf.backgroundColor = .systemGray6
        tf.layer.cornerRadius = 14
        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 48))
        tf.leftViewMode = .always
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let loginButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Log In", for: .normal)
        b.backgroundColor = UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.layer.cornerRadius = 14
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let signUpButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Sign Up", for: .normal)
        b.backgroundColor = UIColor(red: 0.482, green: 0.561, blue: 0.631, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.layer.cornerRadius = 14
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let forgotPasswordButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Forgot Password?", for: .normal)
        b.setTitleColor(.secondaryLabel, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14)
        b.contentHorizontalAlignment = .trailing
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Lifecycle

    /// Called when the view controller's view is loaded into memory.
    /// Sets up the initial view configuration, UI elements, and event handlers.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Layout

    /// Sets up the user interface by creating and positioning all UI elements.
    /// Configures stack views, adds subviews, and activates layout constraints.
    private func setupUI() {
        let fieldStack = UIStackView(arrangedSubviews: [emailField, passwordField, usernameField])
        fieldStack.axis = .vertical
        fieldStack.spacing = 12
        fieldStack.translatesAutoresizingMaskIntoConstraints = false

        let buttonStack = UIStackView(arrangedSubviews: [loginButton, signUpButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(fieldStack)
        view.addSubview(forgotPasswordButton)
        view.addSubview(buttonStack)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 72),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            fieldStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 48),
            fieldStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            fieldStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            emailField.heightAnchor.constraint(equalToConstant: 48),
            passwordField.heightAnchor.constraint(equalToConstant: 48),
            usernameField.heightAnchor.constraint(equalToConstant: 48),

            forgotPasswordButton.topAnchor.constraint(equalTo: fieldStack.bottomAnchor, constant: 8),
            forgotPasswordButton.trailingAnchor.constraint(equalTo: fieldStack.trailingAnchor),

            buttonStack.topAnchor.constraint(equalTo: forgotPasswordButton.bottomAnchor, constant: 16),
            buttonStack.leadingAnchor.constraint(equalTo: fieldStack.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: fieldStack.trailingAnchor),

            loginButton.heightAnchor.constraint(equalToConstant: 50),
            signUpButton.heightAnchor.constraint(equalToConstant: 50),

            activityIndicator.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 20),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    // MARK: - Actions

    /// Handles the login button tap event.
    /// Validates email and password fields, then attempts to sign in the user.
    @objc private func loginTapped() {
        guard
            let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
            let password = passwordField.text, !password.isEmpty
        else {
            showAuthError("Please enter your email and password.")
            return
        }
        setLoading(true)
        AuthService.shared.signIn(email: email, password: password) { [weak self] error in
            DispatchQueue.main.async {
                self?.setLoading(false)
                if let error = error {
                    self?.showAuthError(error.localizedDescription)
                } else {
                    self?.routeToMainApp()
                }
            }
        }
    }

    /// Handles the sign up button tap event.
    /// Validates email, password, and username fields, then attempts to create a new user account.
    @objc private func signUpTapped() {
        guard
            let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
            let password = passwordField.text, !password.isEmpty
        else {
            showAuthError("Please enter your email and password.")
            return
        }
        guard
            let username = usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !username.isEmpty
        else {
            showAuthError("Please enter a username to sign up.")
            return
        }
        setLoading(true)
        AuthService.shared.signUp(email: email, password: password, userName: username) { [weak self] error in
            DispatchQueue.main.async {
                self?.setLoading(false)
                if let error = error {
                    self?.showAuthError(error.localizedDescription)
                } else {
                    self?.routeToMainApp()
                }
            }
        }
    }

    @objc private func forgotPasswordTapped() {
        let vc = ForgotPasswordViewController()
        vc.initialEmail = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    /// Dismisses the keyboard when the user taps outside of text fields.
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Helpers

    /// Shows or hides the loading indicator and disables/enables buttons during authentication.
    /// - Parameter loading: True to show loading state, false to hide it.
    private func setLoading(_ loading: Bool) {
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        loginButton.isEnabled = !loading
        signUpButton.isEnabled = !loading
    }

    /// Navigates to the main application interface after successful authentication.
    private func routeToMainApp() {
        guard let sceneDelegate = view.window?.windowScene?.delegate as? SceneDelegate else { return }
        sceneDelegate.showMainApp()
    }

    /// Displays an error alert with the given message to inform the user of authentication issues.
    /// - Parameter message: The error message to display.
    private func showAuthError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
