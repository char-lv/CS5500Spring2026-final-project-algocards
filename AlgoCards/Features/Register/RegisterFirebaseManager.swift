// ARCHIVED - This file is not part of the active registration flow.
// The live sign-up uses AuthService.signUp() → FirestoreService.createUser().
//
// SCHEMA CONFLICT WARNING:
//   This file writes to Firestore with incompatible field names:
//     "solvedQuestions" (should be "solvedProblemIds")
//     "answers"         (should be "submissions" collection)
//     "comments"        (should be "commentIds")
//   Do not wire this file into the live flow without migrating the schema first.
//
//  RegisterFirebaseManager.swift
//  AlgoCards
//
//  Created by Jia-Wen Wan on 19/3/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import UIKit

extension RegisterViewController {
    

    func registerNewAccount(completion: @escaping (Bool) -> Void) {
        guard let name = registerView.usernameTextField.text, !name.isEmpty else {
            showAlert(message: "Username field cannot be empty.")
            completion(false)
            return
        }
        
        guard let email = registerView.emailTextField.text, !email.isEmpty, isValidEmail(email) else {
            showAlert(message: "Please enter a valid email address.")
            completion(false)
            return
        }
        
        guard let password = registerView.passwordTextField.text, !password.isEmpty else {
            showAlert(message: "Password field cannot be empty.")
            completion(false)
            return
        }
        
        // Create Firebase user with email and password
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                if let authErrorCode = AuthErrorCode(rawValue: error.code) {
                    switch authErrorCode {
                    case .emailAlreadyInUse:
                        self.showAlert(message: "The email address is already in use. Please use a different email.")
                    default:
                        self.showAlert(message: "An error occurred: \(error.localizedDescription)")
                    }
                } else {
                    self.showAlert(message: "An unknown error occurred. Please try again.")
                }
                completion(false)
                return
            }
            
            // The user creation is successful, set the display name
            self.setNameOfTheUserInFirebaseAuth(name: name)
            
            // Store additional user data in Firestore
            if let userID = result?.user.uid {
                self.storeUserDataInFirestore(name: name, email: email, userID: userID)
            }
            completion(true)
        }
    }


    
    // Helper function to validate email format
    func isValidEmail(_ email: String) -> Bool {
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailPattern)
        return emailPredicate.evaluate(with: email)
    }

    // Helper function to show alerts
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Set the name of the user after account creation
    func setNameOfTheUserInFirebaseAuth(name: String) {
        guard let currentUser = Auth.auth().currentUser else {
            showAlert(message: "Unable to retrieve user information. Please try again.")
            return
        }
        
        let changeRequest = currentUser.createProfileChangeRequest()
        changeRequest.displayName = name
        changeRequest.commitChanges { error in
            if error == nil {
                // Profile update is successful, return to the previous screen
                self.navigationController?.popViewController(animated: true)
            } else {
                // Show error if profile update fails
                self.showAlert(message: "Failed to update profile: \(error!.localizedDescription)")
            }
        }
    }
    // Store user data in Firestore
    func storeUserDataInFirestore(name: String, email: String, userID: String) {
        let userData: [String: Any] = [
            "userName": name,
            "email": email,
            "score": 0, // Default score, or fetch from your database later
            "answers": [:], // Default answers
            "solvedQuestions": [], // Default solved questions
            "comments": [] // Default comments
        ]
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).setData(userData) { error in
            if let error = error {
                self.showAlert(message: "Failed to store user data: \(error.localizedDescription)")
            } else {
                // Successfully saved user data
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}