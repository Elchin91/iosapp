//
//  ContentView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Главная", systemImage: "house.fill")
                }
                .tag(Tab.home)

            PaymentsView()
                .tabItem {
                    Label("Платежи", systemImage: "creditcard.fill")
                }
                .tag(Tab.payments)

            AIChatView()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
                .tag(Tab.ai)

            TransfersView()
                .tabItem {
                    Label("Переводы", systemImage: "arrow.left.arrow.right")
                }
                .tag(Tab.transfers)

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(AppColors.primary)
        .onAppear {
            // Настройка цвета таббара
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

enum Tab {
    case home
    case payments
    case ai
    case transfers
    case profile
}

#Preview {
    ContentView()
}
