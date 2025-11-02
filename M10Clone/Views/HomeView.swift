//
//  HomeView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Balance Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Общий баланс")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        Text("15,250.00 ₽")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)

                        HStack {
                            Label("+2,350 ₽", systemImage: "arrow.up.right")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("за этот месяц")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Быстрые действия")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                QuickActionButton(icon: "arrow.up", title: "Отправить", color: AppColors.primary)
                                QuickActionButton(icon: "arrow.down", title: "Получить", color: AppColors.secondary)
                                QuickActionButton(icon: "arrow.left.arrow.right", title: "Обменять", color: AppColors.accent)
                                QuickActionButton(icon: "plus.circle", title: "Пополнить", color: AppColors.primaryLight)
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Recent Transactions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Последние операции")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            TransactionRow(
                                icon: "cart.fill",
                                title: "Пятерочка",
                                date: "Сегодня, 14:23",
                                amount: "-500 ₽",
                                isPositive: false
                            )
                            TransactionRow(
                                icon: "person.fill",
                                title: "От Иван Петров",
                                date: "Вчера, 18:45",
                                amount: "+2,000 ₽",
                                isPositive: true
                            )
                            TransactionRow(
                                icon: "wifi",
                                title: "МТС",
                                date: "01 Ноя, 10:30",
                                amount: "-350 ₽",
                                isPositive: false
                            )
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .background(AppColors.background)
            .navigationTitle("Главная")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                )

            Text(title)
                .font(.caption)
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

struct TransactionRow: View {
    let icon: String
    let title: String
    let date: String
    let amount: String
    let isPositive: Bool

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(AppColors.background)
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(AppColors.primary)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                Text(date)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Text(amount)
                .font(.body.bold())
                .foregroundColor(isPositive ? AppColors.success : AppColors.textPrimary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
}
