//
//  SceneDelegate.swift
//  AlgoCards
//
//  Created by Minghui Xu on 2/26/26.
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

        // Routing

        func routeInitialScreen() {
            if Auth.auth().currentUser != nil {
                showMainApp()
            } else {
                // showAuth() # commented for testing problem view
                showProblemsForTesting()
            }
        }
    
        private func showProblemsForTesting() {
            let homeVC = HomeViewController()
            let nav = UINavigationController(rootViewController: homeVC)
            setRoot(nav)
        }

        func showAuth() {
            // will be replaced by LandingViewController with real implementation
            let landingVC = UIViewController()
            landingVC.view.backgroundColor = .white
            let nav = UINavigationController(rootViewController: landingVC)
            nav.navigationBar.isHidden = true
            setRoot(nav)
        }

        func showMainApp() {
            // will be replaced with MainTabBarController when ready
            let mainVC = UIViewController()
            mainVC.view.backgroundColor = .systemBackground
            setRoot(mainVC)
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

