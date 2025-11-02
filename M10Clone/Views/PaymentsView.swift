//
//  PaymentsView.swift
//  M10Clone
//
//  Created by Claude on 2025-11-02.
//

import SwiftUI

struct PaymentsView: View {
    @State private var searchText = ""

    let categories = [
        PaymentCategory(icon: "phone.fill", title: "Мобильная связь", color: AppColors.primary),
        PaymentCategory(icon: "wifi", title: "Интернет", color: AppColors.secondary),
        PaymentCategory(icon: "bolt.fill", title: "Коммунальные", color: AppColors.accent),
        PaymentCategory(icon: "tv.fill", title: "ТВ и Стриминг", color: AppColors.primaryLight),
        PaymentCategory(icon: "gamecontroller.fill", title: "Игры", color: AppColors.primary),
        PaymentCategory(icon: "cart.fill", title: "Онлайн магазины", color: AppColors.secondary)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppColors.textSecondary)

                        TextField("Поиск услуг", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .background(AppColors.background)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Categories grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(categories) { category in
                            PaymentCategoryCard(category: category)
                        }
                    }
                    .padding(.horizontal)

                    // Recent payments
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Недавние платежи")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            RecentPaymentRow(
                                icon: "phone.fill",
                                title: "МТС",
                                subtitle: "+7 (999) 123-45-67",
                                color: AppColors.error
                            )
                            RecentPaymentRow(
                                icon: "wifi",
                                title: "Ростелеком",
                                subtitle: "Договор 123456789",
                                color: AppColors.primary
                            )
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.vertical)
            }
            .background(Color.white)
            .navigationTitle("Платежи")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct PaymentCategory: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let color: Color
}

struct PaymentCategoryCard: View {
    let category: PaymentCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(category.color.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(category.color)
                )

            Text(category.title)
                .font(.body)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.background)
        .cornerRadius(16)
    }
}

struct RecentPaymentRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(AppColors.textPrimary)
                Text(subtitle)
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

#Preview {
    PaymentsView()
}
