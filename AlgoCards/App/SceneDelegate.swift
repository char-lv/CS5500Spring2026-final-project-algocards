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
        let tabBarVC = UITabBarController()

        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        let socialVC = SocialViewController()
        let socialNav = UINavigationController(rootViewController: socialVC)
        socialNav.tabBarItem = UITabBarItem(
            title: "Social",
            image: UIImage(systemName: "person.2"),
            selectedImage: UIImage(systemName: "person.2.fill")
        )

        let profileVC = ProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person.circle"),
            selectedImage: UIImage(systemName: "person.circle.fill")
        )

        tabBarVC.viewControllers = [homeNav, socialNav, profileNav]

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        let tint = UIColor(red: 139/255, green: 175/255, blue: 139/255, alpha: 1.0)
        tabBarVC.tabBar.tintColor = tint
        tabBarVC.tabBar.standardAppearance = appearance
        tabBarVC.tabBar.scrollEdgeAppearance = appearance

        setRoot(tabBarVC)
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
