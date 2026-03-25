//
//  AuthService.swift
//  AlgoCards
//

import Foundation
import FirebaseAuth

class AuthService {
    static let shared = AuthService()
    private init() {}

    var currentUserId: String? { Auth.auth().currentUser?.uid }
    var isLoggedIn: Bool { Auth.auth().currentUser != nil }

    func signIn(email: String, password: String, completion: @escaping (Error?) -> Void) {
        print("[AuthService] Attempting sign in — email: \(email)")
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("[AuthService] Sign in failed: \(error.localizedDescription)")
                completion(error)
                return
            }
            print("[AuthService] Sign in success — UID: \(result?.user.uid ?? "nil")")
            completion(nil)
        }
    }

    func signUp(email: String, password: String, userName: String, completion: @escaping (Error?) -> Void) {
        print("[AuthService] Attempting sign up — email: \(email), userName: \(userName)")
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("[AuthService] Sign up failed: \(error.localizedDescription)")
                completion(error)
                return
            }
            guard let uid = result?.user.uid else {
                let err = NSError(domain: "AuthService", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Failed to get user ID after sign up."])
                completion(err)
                return
            }
            print("[AuthService] Firebase user created — UID: \(uid). Creating Firestore doc...")
            let user = User(id: uid, userName: userName, email: email)
            FirestoreService.shared.createUser(user) { firestoreError in
                if let firestoreError = firestoreError {
                    print("[AuthService] Firestore user doc creation failed: \(firestoreError.localizedDescription)")
                } else {
                    print("[AuthService] Firestore user doc created — UID: \(uid)")
                }
                completion(firestoreError)
            }
        }
    }

    func resetPassword(email: String, completion: @escaping (Error?) -> Void) {
        print("[AuthService] Sending password reset email to: \(email)")
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                print("[AuthService] Password reset failed: \(error.localizedDescription)")
            } else {
                print("[AuthService] Password reset email sent.")
            }
            completion(error)
        }
    }

    func signOut() {
        print("[AuthService] Signing out — current UID: \(currentUserId ?? "nil")")
        try? Auth.auth().signOut()
        print("[AuthService] Signed out.")
    }
}
