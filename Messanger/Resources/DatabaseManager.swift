//
//  DatabaseManager.swift
//  Messanger
//
//  Created by Filip Zobic on 5.3.22..
//

import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    
}

// MARK: - Account Mgmt

extension DatabaseManager {
    /// Insert new user to database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void) {
        database.child(DatabaseManager.safeEmail(user.emailAddress)).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: {error, _ in
            guard error == nil else {
                print("Failed to write to database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // append to users dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": DatabaseManager.safeEmail(user.emailAddress)
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            return
                        }
                        completion(true)
                        
                    })
                } else {
                    // create dictionary
                    let newCollection: [[String: String]] = [
                        ["name": user.firstName + " " + user.lastName,
                         "email": DatabaseManager.safeEmail(user.emailAddress)
                        ]
                    ]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            return
                        }
                        completion(true)
                        
                    })
                }
            })
            
            completion(true)
        })
    }
    
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)) {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? String != nil else {
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
    
    static func safeEmail(_ emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    
    var profilePictureFileName: String {
        return "\(DatabaseManager.safeEmail(emailAddress))_profile_picture.png"
    }
}
