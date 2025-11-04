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

            HistoryView()
                .tabItem {
                    Label("История", systemImage: "clock.fill")
                }
                .tag(Tab.history)

            ProfileView()
                .tabItem {
                    Label("Профиль", systemImage: "person.fill")
                }
                .tag(Tab.profile)
        }
        .tint(AppColors.colorPrimary)
        .onAppear {
            // Настройка цвета таббара
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.white
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)
            
            // Настройка для неактивных вкладок
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(hex: "8E9198")
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(hex: "8E9198"),
                .font: UIFont.systemFont(ofSize: 11, weight: .regular)
            ]
            
            // Настройка для активных вкладок
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hex: "14234B")
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(hex: "14234B"),
                .font: UIFont.systemFont(ofSize: 11, weight: .regular)
            ]
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        .onChange(of: selectedTab) { newTab in
            // Скрываем клавиатуру при переходе на другую вкладку
            if newTab != .ai {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
}

enum Tab {
    case home
    case payments
    case ai
    case history
    case profile
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

#Preview {
    ContentView()
}
