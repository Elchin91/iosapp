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
                VStack(spacing: 24) {
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
                                .font(.title2.bold())
                                .foregroundColor(AppColors.textPrimary)

                            Text("+7 (999) 123-45-67")
                                .font(.subheadline)
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(.vertical)

                    // Cards section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Мои карты")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            CardRow(
                                cardNumber: "**** 1234",
                                cardType: "M10 Virtual",
                                color: AppColors.primary
                            )
                            CardRow(
                                cardNumber: "**** 5678",
                                cardType: "M10 Premium",
                                color: AppColors.primaryDark
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Settings sections
                    VStack(spacing: 24) {
                        SettingsSection(title: "Основные", items: [
                            SettingItem(icon: "person.fill", title: "Личные данные", color: AppColors.primary),
                            SettingItem(icon: "lock.fill", title: "Безопасность", color: AppColors.secondary),
                            SettingItem(icon: "bell.fill", title: "Уведомления", color: AppColors.accent)
                        ])

                        SettingsSection(title: "Поддержка", items: [
                            SettingItem(icon: "questionmark.circle.fill", title: "Помощь", color: AppColors.primary),
                            SettingItem(icon: "message.fill", title: "Чат с поддержкой", color: AppColors.secondary),
                            SettingItem(icon: "doc.text.fill", title: "Условия использования", color: AppColors.accent)
                        ])

                        SettingsSection(title: "Приложение", items: [
                            SettingItem(icon: "star.fill", title: "Оценить приложение", color: AppColors.warning),
                            SettingItem(icon: "info.circle.fill", title: "О приложении", color: AppColors.primary)
                        ])
                    }

                    // Logout button
                    Button(action: {}) {
                        Text("Выйти")
                            .font(.body.bold())
                            .foregroundColor(AppColors.error)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.error.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .background(Color.white)
            .navigationTitle("Профиль")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "gear")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }
}

struct CardRow: View {
    let cardNumber: String
    let cardType: String
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
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                Text(cardNumber)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }
}

struct SettingsSection: View {
    let title: String
    let items: [SettingItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(items) { item in
                    SettingRow(item: item)
                }
            }
            .padding(.horizontal)
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
            Circle()
                .fill(item.color.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: item.icon)
                        .foregroundColor(item.color)
                        .font(.system(size: 18))
                )

            Text(item.title)
                .font(.body)
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.textSecondary)
                .font(.system(size: 14))
        }
        .padding()
        .background(AppColors.background)
        .cornerRadius(12)
    }
}

#Preview {
    ProfileView()
}
