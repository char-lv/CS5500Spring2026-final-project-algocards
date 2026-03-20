//
//  SceneDelegate.swift
//  AlgoCards
//

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        window = UIWindow(windowScene: windowScene)
        routeInitialScreen()
        window?.makeKeyAndVisible()
    }

    // MARK: - Routing

    func routeInitialScreen() {
        if let user = Auth.auth().currentUser {
            print("[SceneDelegate] Authenticated user found — UID: \(user.uid). Routing to main app.")
            showMainApp()
        } else {
            print("[SceneDelegate] No authenticated user. Routing to auth screen.")
            showAuth()
        }
    }

    func showAuth() {
        let authVC = AuthViewController()
        let nav = UINavigationController(rootViewController: authVC)
        nav.navigationBar.isHidden = true
        setRoot(nav)
    }

    func showMainApp() {
        let homeVC = HomeViewController()
        let nav = UINavigationController(rootViewController: homeVC)
        setRoot(nav)
    }

    private func setRoot(_ vc: UIViewController) {
        window?.rootViewController = vc
        UIView.transition(
            with: window!,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil
        )
    }
}
