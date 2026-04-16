//
//  ForgotPasswordViewController.swift
//  AlgoCards
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    private enum Step { case email, code }
    private var step: Step = .email
    private var targetEmail = ""
    private var resendCooldown = 0
    private var resendTimer: Timer?

    var initialEmail: String?

    // MARK: - Shared UI

    private let backButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("← Back to Login", for: .normal)
        b.setTitleColor(.secondaryLabel, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14)
        b.contentHorizontalAlignment = .leading
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "Forgot Password"
        l.font = .boldSystemFont(ofSize: 28)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Enter your email to receive a verification code."
        l.font = .systemFont(ofSize: 15)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.hidesWhenStopped = true
        ai.translatesAutoresizingMaskIntoConstraints = false
        return ai
    }()

    // MARK: - Step 1: Email

    private let emailField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        tf.autocorrectionType = .no
        tf.borderStyle = .roundedRect
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let sendCodeButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Send Code", for: .normal)
        b.backgroundColor = UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.layer.cornerRadius = 12
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Step 2: Code

    private let codeField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "6-digit code"
        tf.keyboardType = .numberPad
        tf.borderStyle = .roundedRect
        tf.textAlignment = .center
        tf.font = .monospacedDigitSystemFont(ofSize: 28, weight: .medium)
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private let verifyButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Verify", for: .normal)
        b.backgroundColor = UIColor(red: 0.545, green: 0.686, blue: 0.545, alpha: 1)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .boldSystemFont(ofSize: 17)
        b.layer.cornerRadius = 12
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private let resendButton: UIButton = {
        let b = UIButton(type: .system)
        b.setTitle("Resend Code", for: .normal)
        b.setTitleColor(.secondaryLabel, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 14)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // Step containers
    private let emailStepView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let codeStepView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        bindActions()
        if let email = initialEmail {
            emailField.text = email
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Layout

    private func setupUI() {
        let emailStack = UIStackView(arrangedSubviews: [emailField, sendCodeButton])
        emailStack.axis = .vertical
        emailStack.spacing = 16
        emailStack.translatesAutoresizingMaskIntoConstraints = false
        emailStepView.addSubview(emailStack)
        NSLayoutConstraint.activate([
            emailField.heightAnchor.constraint(equalToConstant: 48),
            sendCodeButton.heightAnchor.constraint(equalToConstant: 50),
            emailStack.topAnchor.constraint(equalTo: emailStepView.topAnchor),
            emailStack.leadingAnchor.constraint(equalTo: emailStepView.leadingAnchor),
            emailStack.trailingAnchor.constraint(equalTo: emailStepView.trailingAnchor),
            emailStack.bottomAnchor.constraint(equalTo: emailStepView.bottomAnchor),
        ])

        let codeStack = UIStackView(arrangedSubviews: [codeField, verifyButton, resendButton])
        codeStack.axis = .vertical
        codeStack.spacing = 16
        codeStack.translatesAutoresizingMaskIntoConstraints = false
        codeStepView.addSubview(codeStack)
        NSLayoutConstraint.activate([
            codeField.heightAnchor.constraint(equalToConstant: 60),
            verifyButton.heightAnchor.constraint(equalToConstant: 50),
            codeStack.topAnchor.constraint(equalTo: codeStepView.topAnchor),
            codeStack.leadingAnchor.constraint(equalTo: codeStepView.leadingAnchor),
            codeStack.trailingAnchor.constraint(equalTo: codeStepView.trailingAnchor),
            codeStack.bottomAnchor.constraint(equalTo: codeStepView.bottomAnchor),
        ])
        codeStepView.isHidden = true

        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(emailStepView)
        view.addSubview(codeStepView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),

            titleLabel.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            emailStepView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 36),
            emailStepView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emailStepView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            codeStepView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 36),
            codeStepView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            codeStepView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            activityIndicator.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 160),
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private func bindActions() {
        sendCodeButton.addTarget(self, action: #selector(sendCodeTapped), for: .touchUpInside)
        verifyButton.addTarget(self, action: #selector(verifyTapped), for: .touchUpInside)
        resendButton.addTarget(self, action: #selector(resendTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func sendCodeTapped() {
        let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !email.isEmpty else { showError("Please enter your email address."); return }
        guard AuthValidation.isValidEmail(email) else { showError("Please enter a valid email address."); return }
        targetEmail = email
        setLoading(true)
        VerificationService.shared.sendCode(to: email, completion: onSendCodeResult)
    }

    private func onSendCodeResult(error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.setLoading(false)
            if let error = error { self?.showError(error.localizedDescription) }
            else { self?.transitionToCodeStep() }
        }
    }

    @objc private func verifyTapped() {
        let code = codeField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard code.count == 6, code.allSatisfy({ $0.isNumber }) else {
            showError("Please enter the 6-digit code sent to your email.")
            return
        }
        setLoading(true)
        VerificationService.shared.verifyCode(code, for: targetEmail, completion: onVerifyResult)
    }

    private func onVerifyResult(valid: Bool, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.setLoading(false)
            if let error = error { self?.showError(error.localizedDescription); return }
            if valid { self?.sendPasswordResetAndFinish() }
            else { self?.showError("Incorrect or expired code. Please try again.") }
        }
    }

    @objc private func resendTapped() {
        guard resendCooldown == 0 else { return }
        setLoading(true)
        VerificationService.shared.sendCode(to: targetEmail, completion: onResendResult)
    }

    private func onResendResult(error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.setLoading(false)
            if let error = error { self?.showError(error.localizedDescription) }
            else { self?.startResendCooldown(); self?.showInfo("A new code has been sent to \(self?.targetEmail ?? "your email").") }
        }
    }

    @objc private func backTapped() {
        dismiss(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Helpers

    private func transitionToCodeStep() {
        step = .code
        subtitleLabel.text = "Enter the 6-digit code sent to \(targetEmail)."
        UIView.transition(with: view, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.emailStepView.isHidden = true
            self.codeStepView.isHidden = false
        }, completion: nil)
        startResendCooldown()
        codeField.becomeFirstResponder()
    }

    private func sendPasswordResetAndFinish() {
        setLoading(true)
        AuthService.shared.resetPassword(email: targetEmail, completion: onResetResult)
    }

    private func onResetResult(error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setLoading(false)
            if let error = error { self.showError(error.localizedDescription); return }
            let alert = UIAlertController(
                title: "Check Your Email",
                message: "Your identity has been verified. A password reset link has been sent to \(self.targetEmail). Please check your inbox.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in self?.dismiss(animated: true) })
            self.present(alert, animated: true)
        }
    }

    private func startResendCooldown(seconds: Int = 60) {
        resendCooldown = seconds
        resendButton.isEnabled = false
        resendTimer?.invalidate()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            self.resendCooldown -= 1
            if self.resendCooldown <= 0 {
                timer.invalidate()
                self.resendButton.setTitle("Resend Code", for: .normal)
                self.resendButton.isEnabled = true
            } else {
                self.resendButton.setTitle("Resend Code (\(self.resendCooldown)s)", for: .normal)
            }
        }
    }

    private func setLoading(_ loading: Bool) {
        loading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
        sendCodeButton.isEnabled = !loading
        verifyButton.isEnabled = !loading
        resendButton.isEnabled = !loading && resendCooldown == 0
    }

    private func showInfo(_ message: String) {
        showAlert(title: "Info", message: message)
    }
}
