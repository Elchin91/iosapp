//
//  ProfileView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // User profile header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text("АП")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(.white)
                            )

                        VStack(spacing: 4) {
                            Text("Александр Петров")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            Text("+994 50 123 45 67")
                                .font(.system(size: 15))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 24)

                    // Stats cards
                    HStack(spacing: 12) {
                        StatCard(title: "Баланс", value: "15,250 ₼", icon: "wallet.pass.fill", color: AppColors.primary)
                        StatCard(title: "Lim10", value: "1,250", icon: "star.fill", color: Color(hex: "FFD700"))
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)

                    // Cards section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Мои карты")
                                .font(.system(size: 20, weight: .bold))
                            Spacer()
                            Button("Все") {
                                // Показать все карты
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppColors.primary)
                        }
                        .padding(.horizontal, 16)

                        VStack(spacing: 0) {
                            CardRow(
                                cardNumber: "**** 1234",
                                cardType: "M10 Virtual",
                                balance: "15,250 ₼",
                                color: AppColors.primary
                            )
                            Divider().padding(.leading, 72)
                            CardRow(
                                cardNumber: "**** 5678",
                                cardType: "M10 Premium",
                                balance: "5,000 ₼",
                                color: AppColors.primaryDark
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 24)

                    // Settings sections
                    VStack(spacing: 20) {
                        SettingsSection(title: "Основные", items: [
                            SettingItem(icon: "person.fill", title: "Личные данные", color: AppColors.primary),
                            SettingItem(icon: "lock.fill", title: "Безопасность", color: AppColors.secondary),
                            SettingItem(icon: "bell.fill", title: "Уведомления", color: AppColors.accent),
                            SettingItem(icon: "creditcard.fill", title: "Карты и счета", color: Color(hex: "4ECDC4"))
                        ])

                        SettingsSection(title: "Поддержка", items: [
                            SettingItem(icon: "questionmark.circle.fill", title: "Помощь", color: AppColors.primary),
                            SettingItem(icon: "message.fill", title: "Чат с поддержкой", color: AppColors.secondary),
                            SettingItem(icon: "doc.text.fill", title: "Условия использования", color: AppColors.accent),
                            SettingItem(icon: "info.circle.fill", title: "О приложении", color: Color(hex: "9B59B6"))
                        ])

                        SettingsSection(title: "Приложение", items: [
                            SettingItem(icon: "star.fill", title: "Оценить приложение", color: AppColors.warning),
                            SettingItem(icon: "square.and.arrow.up.fill", title: "Поделиться", color: AppColors.primary)
                        ])
                    }
                    .padding(.bottom, 24)

                    // Logout button
                    Button(action: {}) {
                        Text("Выйти")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.error)
                            .frame(maxWidth: .infinity)
                            .padding(16)
                            .background(AppColors.error.opacity(0.1))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Профиль")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct CardRow: View {
    let cardNumber: String
    let cardType: String
    let balance: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 40)
                .overlay(
                    Image(systemName: "creditcard.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(cardType)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                Text(cardNumber)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(balance)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Баланс")
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
    }
}

struct SettingsSection: View {
    let title: String
    let items: [SettingItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.horizontal, 16)

            VStack(spacing: 0) {
                ForEach(items) { item in
                    SettingRow(item: item)
                    if item.id != items.last?.id {
                        Divider().padding(.leading, 72)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }
}

struct SettingItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

struct SettingRow: View {
    let item: SettingItem

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(item.color)
                .clipShape(Circle())

            Text(item.title)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(16)
    }
}

#Preview {
    ProfileView()
}
