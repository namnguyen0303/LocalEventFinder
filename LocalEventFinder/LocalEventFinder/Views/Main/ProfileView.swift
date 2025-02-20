//
//  ProfileView.swift
//  LocalEventFinder
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfile {
    var displayName: String
    var email: String
    var dateOfBirth: Date?
    
    init(displayName: String = "", email: String = "", dateOfBirth: Date? = nil) {
        self.displayName = displayName
        self.email = email
        self.dateOfBirth = dateOfBirth
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showSignOutAlert = false
    @State private var showingEditProfile = false
    @State private var userProfile = UserProfile()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.blue)
                                    .padding(20)
                            )
                            .padding(.top, 20)
                        
                        Text(userProfile.displayName.isEmpty ? "No Name Set" : userProfile.displayName)
                            .font(.headline)
                        
                        Text(userProfile.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Edit Profile") {
                            showingEditProfile = true
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Profile Info Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Profile Information")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            infoRow(icon: "person", title: "Name", value: userProfile.displayName.isEmpty ? "Not set" : userProfile.displayName)
                            Divider().padding(.leading, 56)
                            infoRow(icon: "envelope", title: "Email", value: userProfile.email)
                            if let dob = userProfile.dateOfBirth {
                                Divider().padding(.leading, 56)
                                infoRow(icon: "calendar", title: "Date of Birth", value: formatDate(dob))
                            }
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Settings")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            settingsButton(icon: "bell", title: "Notifications", action: {})
                            Divider().padding(.leading, 56)
                            settingsButton(icon: "location", title: "Default Location", action: {})
                            Divider().padding(.leading, 56)
                            settingsButton(icon: "gear", title: "Preferences", action: {})
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Sign Out Button
                    Button(action: { showSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("Sign Out")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(userProfile: userProfile) { updatedProfile in
                    updateProfile(with: updatedProfile)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    do {
                        try authViewModel.signOut()
                    } catch {
                        print("Error signing out: \(error.localizedDescription)")
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .onAppear {
                fetchUserProfile()
            }
        }
    }
    
    private func fetchUserProfile() {
        guard let currentUser = Auth.auth().currentUser else { return }
        
        // Set the email immediately from Auth
        userProfile.email = currentUser.email ?? ""
        
        let db = Firestore.firestore()
        db.collection("users").document(currentUser.uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user profile: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                let data = document.data() ?? [:]
                userProfile.displayName = data["displayName"] as? String ?? ""
                if let dobTimestamp = data["dateOfBirth"] as? Timestamp {
                    userProfile.dateOfBirth = dobTimestamp.dateValue()
                }
            }
        }
    }
    
    private func updateProfile(with updatedProfile: UserProfile) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        var userData: [String: Any] = [
            "displayName": updatedProfile.displayName
        ]
        
        if let dob = updatedProfile.dateOfBirth {
            userData["dateOfBirth"] = Timestamp(date: dob)
        }
        
        db.collection("users").document(userId).setData(userData, merge: true) { error in
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
            } else {
                self.userProfile = updatedProfile
            }
        }
    }
    
    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(.blue)
                .padding(.leading)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
            .padding(.leading, 8)
            
            Spacer()
        }
        .frame(height: 60)
    }
    
    private func settingsButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue)
                    .padding(.leading)
                
                Text(title)
                    .foregroundColor(.primary)
                    .padding(.leading, 8)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding(.trailing)
            }
            .frame(height: 44)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct EditProfileView: View {
    let userProfile: UserProfile
    let onSave: (UserProfile) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var showingDatePicker = false
    
    init(userProfile: UserProfile, onSave: @escaping (UserProfile) -> Void) {
        self.userProfile = userProfile
        self.onSave = onSave
        _displayName = State(initialValue: userProfile.displayName)
        if let dob = userProfile.dateOfBirth {
            _dateOfBirth = State(initialValue: dob)
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Display Name", text: $displayName)
                    
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Text("Date of Birth")
                            Spacer()
                            Text(formatDate(dateOfBirth))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedProfile = userProfile
                        updatedProfile.displayName = displayName
                        updatedProfile.dateOfBirth = dateOfBirth
                        onSave(updatedProfile)
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(date: $dateOfBirth, isPresented: $showingDatePicker)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct DatePickerSheet: View {
    @Binding var date: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            DatePicker(
                "Date of Birth",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
