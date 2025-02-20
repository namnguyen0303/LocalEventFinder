//
//  LoginView.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo and Title
                        VStack(spacing: 15) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Local Event Finder")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Sign in to discover events near you")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 50)
                        
                        // Input Fields
                        VStack(spacing: 20) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .foregroundColor(.secondary)
                                    .font(.callout)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                    TextField("your@email.com", text: $email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .focused($focusedField, equals: .email)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .foregroundColor(.secondary)
                                    .font(.callout)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.gray)
                                    Group {
                                        if isPasswordVisible {
                                            TextField("Enter password", text: $password)
                                        } else {
                                            SecureField("Enter password", text: $password)
                                        }
                                    }
                                    .focused($focusedField, equals: .password)
                                    
                                    Button {
                                        isPasswordVisible.toggle()
                                    } label: {
                                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Sign In Button
                        Button(action: login) {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .disabled(authViewModel.isLoading)
                        
                        // Sign Up Link
                        NavigationLink(destination: SignUpView()) {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(.secondary)
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding()
                }
            }
            .alert("Sign In Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authViewModel.error?.localizedDescription ?? "Please check your credentials and try again.")
            }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
        }
    }
    
    private func login() {
        focusedField = nil // Dismiss keyboard
        Task {
            do {
                try await authViewModel.signIn(email: email, password: password)
            } catch {
                showingError = true
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
