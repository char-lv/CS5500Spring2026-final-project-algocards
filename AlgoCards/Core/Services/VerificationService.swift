//
//  VerificationService.swift
//  AlgoCards
//
//  Stores one-time verification codes in Firestore and triggers email delivery
//  via the Firebase "Trigger Email" extension (collection: "mail").
//

import Foundation
import FirebaseFirestore

class VerificationService {
    static let shared = VerificationService()
    private init() {}

    private let db = Firestore.firestore()
    private let codeExpirySeconds: TimeInterval = 10 * 60

    func sendCode(to email: String, completion: @escaping (Error?) -> Void) {
        let code = String(format: "%06d", Int.random(in: 0...999999))
        let expiresAt = Timestamp(date: Date().addingTimeInterval(codeExpirySeconds))

        let codeDoc: [String: Any] = [
            "code": code,
            "expiresAt": expiresAt,
            "used": false
        ]

        db.collection("verificationCodes").document(email).setData(codeDoc) { [weak self] error in
            if let error = error { completion(error); return }
            self?.triggerEmail(to: email, code: code, completion: completion)
        }
    }

    func verifyCode(_ code: String, for email: String, completion: @escaping (Bool, Error?) -> Void) {
        db.collection("verificationCodes").document(email).getDocument { snapshot, error in
            if let error = error {
                completion(false, error)
                return
            }
            guard
                let data = snapshot?.data(),
                let stored = data["code"] as? String,
                let expiresAt = (data["expiresAt"] as? Timestamp)?.dateValue(),
                let used = data["used"] as? Bool,
                !used,
                Date() < expiresAt,
                code == stored
            else {
                completion(false, nil)
                return
            }
            snapshot?.reference.updateData(["used": true]) { _ in }
            completion(true, nil)
        }
    }

    private func triggerEmail(to email: String, code: String, completion: @escaping (Error?) -> Void) {
        let mailDoc: [String: Any] = [
            "to": email,
            "message": [
                "subject": "AlgoCards — Your Verification Code",
                "text": "Your AlgoCards verification code is: \(code)\n\nThis code expires in 10 minutes. Do not share it with anyone.\n\nIf you did not request this, you can safely ignore this email."
            ]
        ]
        db.collection("mail").addDocument(data: mailDoc) { error in
            completion(error)
        }
    }
}
