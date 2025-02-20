//
//  MainTabView.swift
//  LocalEventFinder
//
//  Created by Nam Nguyen on 11/26/24.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            EventListView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                        .environment(\.symbolVariants, .fill)
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                        .environment(\.symbolVariants, .fill)
                }
        }
        .tint(.blue)
    }
}
