//
//  AuthViewModel.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var error: Error?
    @Published var isLoading = false
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var stateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        print("AuthViewModel initialized")
        setupAuthStateListener()
    }
    
    deinit {
        if let listener = stateListener {
            auth.removeStateDidChangeListener(listener)
            print("Auth state listener removed")
        }
    }
    
    private func setupAuthStateListener() {
        stateListener = auth.addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            print("Auth state changed. User: \(user?.uid ?? "none")")
            
            if let firebaseUser = user {
                Task {
                    await self.fetchUserData(for: firebaseUser.uid)
                }
            } else {
                DispatchQueue.main.async {
                    self.user = nil
                    self.isAuthenticated = false
                }
            }
        }
    }
    
    private func fetchUserData(for uid: String) async {
        do {
            print("Fetching user data for uid: \(uid)")
            let document = try await db.collection("users")
                .document(uid)
                .getDocument()
            
            if let data = document.data() {
                let user = User(
                    id: data["uid"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    favorites: data["favorites"] as? [String] ?? []
                )
                
                print("User data fetched successfully: \(user.email)")
                DispatchQueue.main.async {
                    self.user = user
                    self.isAuthenticated = true
                    self.error = nil
                }
            } else {
                print("No user data found for uid: \(uid)")
                DispatchQueue.main.async {
                    self.error = NSError(domain: "AuthViewModel", code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "User data not found"])
                }
            }
        } catch {
            print("Error fetching user data: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            
            let document = try await db.collection("users")
                .document(result.user.uid)
                .getDocument()
            
            if let data = document.data() {
                let user = User(
                    id: data["uid"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    favorites: data["favorites"] as? [String] ?? []
                )
                
                print("User signed in successfully: \(email)")
                await MainActor.run {
                    self.user = user
                    self.isAuthenticated = true
                    self.error = nil
                    self.isLoading = false
                }
            }
        } catch {
            print("Sign in error: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws {
        print("Attempting to sign up user: \(email)")
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            let newUser = User(id: result.user.uid,
                             email: email,
                             favorites: [])
            
            let userData: [String: Any] = [
                "uid": newUser.id,
                "email": newUser.email,
                "favorites": newUser.favorites,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            try await db.collection("users")
                .document(result.user.uid)
                .setData(userData)
            
            print("User signed up successfully: \(email)")
            await MainActor.run {
                self.user = newUser
                self.isAuthenticated = true
                self.error = nil
            }
        } catch {
            print("Sign up error: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    func signOut() throws {
        print("Attempting to sign out")
        do {
            try auth.signOut()
            print("User signed out successfully")
            DispatchQueue.main.async {
                self.user = nil
                self.isAuthenticated = false
                self.error = nil
            }
        } catch {
            print("Sign out error: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.error = error
            }
            throw error
        }
    }
    
    func checkAuthStatus() {
        if let currentUser = auth.currentUser {
            print("Current user found: \(currentUser.uid)")
            Task {
                await fetchUserData(for: currentUser.uid)
            }
        } else {
            print("No current user found")
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.user = nil
            }
        }
    }
    
    func updateUserFavorites(_ favorites: [String]) async throws {
        guard let userId = user?.id else {
            throw NSError(domain: "AuthViewModel", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        try await db.collection("users")
            .document(userId)
            .updateData(["favorites": favorites])
        
        DispatchQueue.main.async {
            self.user?.favorites = favorites
        }
    }
}
